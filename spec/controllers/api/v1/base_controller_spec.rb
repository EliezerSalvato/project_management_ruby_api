require "rails_helper"

# Covers BaseController behavior no current endpoint exercises; endpoints themselves are covered by request specs.
RSpec.describe API::V1::BaseController, type: :controller do
  controller(described_class) do
    skip_before_action :authenticate_user!

    def index
      params.require(:name)
    end

    def show
      render_json_with_success(status: :ok, data: [ params[:id] ])
    end

    def create
      raise "secret internal detail"
    end

    def update
      set_refresh_token_as_cookie(refresh_token: "refresh-token")
      head :ok
    end
  end

  context "in production" do
    before do
      allow(Rails.env).to receive(:production?).and_return(true)
      request.env["HTTPS"] = "on"
    end

    it "hides the exception message behind a generic error" do
      post :create

      expect(response).to have_http_status(:internal_server_error)
      expect(response.parsed_body["message"]).to eq(I18n.t("api.errors.internal_server_error"))
    end

    it "sets the refresh token cookie as Secure and SameSite=None for the cross-site frontend" do
      patch :update, params: { id: "1" }

      cookie = Array(response.headers["Set-Cookie"]).find { it.start_with?("refresh_token=") }

      expect(cookie).to match(/secure/i).and match(/samesite=none/i).and match(/httponly/i)
    end
  end

  it "answers 400 when a required param is missing" do
    get :index

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body).to include("status" => "error", "message" => a_string_including("name"))
  end

  it "marks array data as a collection" do
    get :show, params: { id: "42" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("status" => "success", "type" => "collection", "data" => [ "42" ])
  end
end
