require "rails_helper"

RSpec.describe "Active Storage routes", type: :request do
  describe "POST /rails/active_storage/direct_uploads" do
    it "is not routed, so anonymous clients cannot create blobs" do
      blob = { filename: "page.html", byte_size: 5, checksum: Digest::MD5.base64digest("hello"), content_type: "text/html" }

      expect {
        post "/rails/active_storage/direct_uploads", params: { blob: }, as: :json
      }.not_to change(ActiveStorage::Blob, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT /rails/active_storage/disk/:encoded_token" do
    it "is not routed, so anonymous clients cannot write files to disk" do
      put "/rails/active_storage/disk/token", params: "hello", headers: { "CONTENT_TYPE" => "text/html" }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET cover image URL" do
    it "redirects to the disk service and downloads the file" do
      project = create(:project, :with_cover_image)

      get Rails.application.routes.url_helpers.rails_blob_url(project.cover_image)
      expect(response).to have_http_status(:redirect)

      get response.location
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(project.cover_image.download)
    end
  end
end
