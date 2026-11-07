require "rails_helper"

RSpec.describe "Project endpoints access", type: :request do
  let(:user) { create(:user, :verified) }
  let(:headers) { auth_headers_for(user) }
  let(:own_project) { create(:project, user:) }
  let(:foreign_project) { create(:project, name: "Foreign Project", favorite: false) }

  def member_requests(id)
    {
      "GET /api/v1/projects/:id" => -> { get "/api/v1/projects/#{id}", headers: headers },
      "PATCH /api/v1/projects/:id" => -> { patch "/api/v1/projects/#{id}", params: { name: "Hijacked Project" }, headers: headers },
      "DELETE /api/v1/projects/:id" => -> { delete "/api/v1/projects/#{id}", headers: headers },
      "POST /api/v1/projects/:id/favorite" => -> { post "/api/v1/projects/#{id}/favorite", headers: headers },
      "DELETE /api/v1/projects/:id/favorite" => -> { delete "/api/v1/projects/#{id}/favorite", headers: headers }
    }
  end

  it "answers 404 on every project endpoint for a missing or another user's project" do
    [ SecureRandom.uuid, foreign_project.id ].each do |id|
      member_requests(id).each do |endpoint, request|
        request.call

        expect(response).to have_http_status(:not_found), "#{endpoint} with #{id} answered #{response.status}"
        expect(response.parsed_body["message"]).to eq(I18n.t("api.errors.not_found"))
      end
    end

    expect(foreign_project.reload).to have_attributes(name: "Foreign Project", favorite: false)
  end

  it "answers 404 in the locale from the cookie for a project deleted in the meantime" do
    id = own_project.id
    own_project.destroy!
    cookies[:locale] = "pt-BR"

    member_requests(id).each do |endpoint, request|
      request.call

      expect(response).to have_http_status(:not_found), "#{endpoint} answered #{response.status}"
      expect(response.parsed_body["message"]).to eq(I18n.t("api.errors.not_found", locale: :"pt-BR"))
    end
  end

  it "answers 401 on every project endpoint without a valid session token" do
    id = own_project.id
    requests = {
      "GET /api/v1/projects" => -> { get "/api/v1/projects" },
      "POST /api/v1/projects" => -> { post "/api/v1/projects", params: { name: "New Project" } },
      "GET /api/v1/projects/:id" => -> { get "/api/v1/projects/#{id}" },
      "PATCH /api/v1/projects/:id" => -> { patch "/api/v1/projects/#{id}", params: { name: "Other Name" } },
      "DELETE /api/v1/projects/:id" => -> { delete "/api/v1/projects/#{id}" },
      "POST /api/v1/projects/:id/favorite" => -> { post "/api/v1/projects/#{id}/favorite" },
      "DELETE /api/v1/projects/:id/favorite" => -> { delete "/api/v1/projects/#{id}/favorite" }
    }

    requests.each do |endpoint, request|
      request.call

      expect(response).to have_http_status(:unauthorized), "#{endpoint} answered #{response.status}"
      expect(response.parsed_body["message"]).to eq(I18n.t("user.errors.unauthorized"))
    end

    expect(Project.find(id)).to have_attributes(name: own_project.name, favorite: false)
  end
end
