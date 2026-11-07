require "rails_helper"

RSpec.describe "Project favorites", type: :request do
  let(:user) { create(:user, :verified) }
  let(:headers) { auth_headers_for(user) }
  let(:project) { create(:project, user:, favorite: false) }

  def favorite_project(id, headers, params = {})
    post "/api/v1/projects/#{id}/favorite", params: params, headers: headers, as: :json
  end

  def unfavorite_project(id, headers, params = {})
    delete "/api/v1/projects/#{id}/favorite", params: params, headers: headers, as: :json
  end

  def favorite_attribute
    response.parsed_body.dig("data", "project", "data", "attributes", "favorite")
  end

  describe "POST /api/v1/projects/:project_id/favorite" do
    it "marks the project as favorite" do
      favorite_project(project.id, headers)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("success")
      expect(favorite_attribute).to be(true)
      expect(project.reload.favorite).to be(true)
    end

    it "keeps favorite true when already favorited" do
      project.update!(favorite: true)

      favorite_project(project.id, headers)

      expect(response).to have_http_status(:ok)
      expect(favorite_attribute).to be(true)
      expect(project.reload.favorite).to be(true)
    end

    context "when unauthenticated" do
      subject { favorite_project(project.id, {}) }

      it_behaves_like "an unauthorized API request"
    end
  end

  describe "DELETE /api/v1/projects/:project_id/favorite" do
    it "unmarks the project as favorite" do
      project.update!(favorite: true)

      unfavorite_project(project.id, headers)

      expect(response).to have_http_status(:ok)
      expect(favorite_attribute).to be(false)
      expect(project.reload.favorite).to be(false)
    end

    it "keeps favorite false when not favorited" do
      unfavorite_project(project.id, headers)

      expect(response).to have_http_status(:ok)
      expect(favorite_attribute).to be(false)
      expect(project.reload.favorite).to be(false)
    end

    context "when unauthenticated" do
      subject { unfavorite_project(project.id, {}) }

      it_behaves_like "an unauthorized API request"
    end
  end

  it "changes no field other than favorite" do
    extra = { name: "Changed Name", client_name: "Changed Client", start_date: (Date.current + 1.day).iso8601, end_date: (Date.current + 2.days).iso8601 }
    before = project.attributes.slice("name", "client_name", "start_date", "end_date")

    favorite_project(project.id, headers, extra)

    expect(project.reload.attributes.slice("name", "client_name", "start_date", "end_date")).to eq(before)
    expect(project.favorite).to be(true)

    unfavorite_project(project.id, headers, extra)

    expect(project.reload.attributes.slice("name", "client_name", "start_date", "end_date")).to eq(before)
    expect(project.favorite).to be(false)
  end
end
