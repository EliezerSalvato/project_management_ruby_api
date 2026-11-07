require "rails_helper"

RSpec.describe "DELETE /api/v1/projects/:id", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user, :verified) }
  let(:headers) { auth_headers_for(user) }
  let!(:project) { create(:project, :with_cover_image, user:) }

  def destroy_project(id, headers)
    delete "/api/v1/projects/#{id}", headers: headers
  end

  context "when authenticated" do
    it "deletes the project and its cover image" do
      blob = project.cover_image.blob

      expect { perform_enqueued_jobs { destroy_project(project.id, headers) } }
        .to change(Project, :count).by(-1)
        .and change(ActiveStorage::Attachment, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("success")
      expect(response.parsed_body["message"]).to eq(I18n.t("project.deletion.success"))
      expect(ActiveStorage::Blob.exists?(blob.id)).to be(false)
    end

    it "answers 404 for another user's project" do
      other = create(:project)

      expect { destroy_project(other.id, headers) }.not_to change(Project, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when unauthenticated" do
    subject { destroy_project(project.id, {}) }

    it_behaves_like "an unauthorized API request"
  end
end
