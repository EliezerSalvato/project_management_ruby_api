require "rails_helper"

RSpec.describe "GET /api/v1/projects/:id", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, :verified) }
  let(:headers) { auth_headers_for(user) }
  let(:project) { create(:project, :with_cover_image, user:, favorite: true) }

  def show_project(id, headers)
    get "/api/v1/projects/#{id}", headers: headers
  end

  context "when authenticated" do
    it "returns the project's id, name, client name, dates, favorite and cover image URL" do
      freeze_time
      show_project(project.id, headers)

      attributes = response.parsed_body.dig("data", "project", "data", "attributes")

      expect(response.parsed_body.dig("data", "project", "data", "type")).to eq("project")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("success")
      expect(attributes).to eq(
        "id" => project.id,
        "name" => project.name,
        "client_name" => project.client_name,
        "start_date" => project.start_date.iso8601,
        "end_date" => project.end_date.iso8601,
        "favorite" => true,
        "cover_image_url" => Rails.application.routes.url_helpers.rails_blob_url(project.cover_image)
      )
    end

    it "returns a cover image URL that stops working after an hour" do
      show_project(project.id, headers)
      url = response.parsed_body.dig("data", "project", "data", "attributes", "cover_image_url")

      get url
      expect(response).to have_http_status(:redirect)

      travel 1.hour + 1.second do
        get url
        expect(response).to have_http_status(:not_found)
      end
    end

    it "answers 404 for another user's project" do
      show_project(create(:project).id, headers)

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["status"]).to eq("error")
      expect(response.parsed_body["message"]).to eq(I18n.t("api.errors.not_found"))
    end

    it "answers 404 for a missing project" do
      show_project(SecureRandom.uuid, headers)

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["message"]).to eq(I18n.t("api.errors.not_found"))
    end
  end

  context "when unauthenticated" do
    subject { show_project(project.id, {}) }

    it_behaves_like "an unauthorized API request"
  end
end
