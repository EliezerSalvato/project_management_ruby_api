require "rails_helper"

RSpec.describe "PATCH /api/v1/projects/:id", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user, :verified) }
  let(:headers) { auth_headers_for(user) }
  let(:project) do
    create(:project, :with_cover_image, user:, name: "Website Redesign", client_name: "Acme Corp",
      start_date: Date.current, end_date: Date.current + 10.days)
  end

  def update_project(id, params, headers)
    patch "/api/v1/projects/#{id}", params: params, headers: headers
  end

  def project_attributes
    response.parsed_body.dig("data", "project", "data", "attributes")
  end

  def stored_state(project)
    project.reload.attributes.slice("name", "client_name", "start_date", "end_date", "favorite")
  end

  def png_of_size(size)
    header = File.binread(Rails.root.join("spec/fixtures/files/cover.png"))
    file = Tempfile.new([ "big", ".png" ])
    file.binmode
    file.write(header + ("\0" * (size - header.bytesize)))
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "image/png")
  end

  context "when authenticated" do
    it "ignores favorite sent on update" do
      update_project(project.id, { favorite: true }, headers)

      expect(response).to have_http_status(:ok)
      expect(project_attributes["favorite"]).to be(false)
      expect(project.reload.favorite).to be(false)
    end

    it "updates only the fields sent and keeps the rest" do
      blob_id = project.cover_image.blob.id

      update_project(project.id, { name: "Mobile App" }, headers)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to eq(I18n.t("project.update.success"))
      expect(project.reload).to have_attributes(
        name: "Mobile App",
        client_name: "Acme Corp",
        start_date: Date.current,
        end_date: Date.current + 10.days
      )
      expect(project.cover_image.blob.id).to eq(blob_id)
      expect(project_attributes).to include("name" => "Mobile App", "client_name" => "Acme Corp")
    end

    it "removes the cover image with remove_cover_image=true and keeps the other fields" do
      old_blob = project.cover_image.blob

      perform_enqueued_jobs { update_project(project.id, { remove_cover_image: "true" }, headers) }

      expect(response).to have_http_status(:ok)
      expect(project_attributes["cover_image_url"]).to be_nil
      expect(project.reload.cover_image).not_to be_attached
      expect(project).to have_attributes(name: "Website Redesign", client_name: "Acme Corp")
      expect(ActiveStorage::Blob.exists?(old_blob.id)).to be(false)
    end

    it "removes the cover image with remove_cover_image=true sent as JSON" do
      patch "/api/v1/projects/#{project.id}", params: { remove_cover_image: true }.to_json,
        headers: headers.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:ok)
      expect(project.reload.cover_image).not_to be_attached
    end

    it "keeps the cover image when remove_cover_image is false or absent" do
      blob_id = project.cover_image.blob.id

      [ { remove_cover_image: "false" }, { remove_cover_image: "" }, { name: "Mobile App" } ].each do |params|
        update_project(project.id, params, headers)

        expect(response).to have_http_status(:ok)
        expect(project.reload.cover_image.blob.id).to eq(blob_id)
      end
    end

    it "answers 200 when removing the cover image of a project without one" do
      bare = create(:project, user:)

      update_project(bare.id, { remove_cover_image: "true" }, headers)

      expect(response).to have_http_status(:ok)
      expect(bare.reload.cover_image).not_to be_attached
    end

    it "uses the new upload when cover_image and remove_cover_image=true come together" do
      old_blob = project.cover_image.blob
      new_cover = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/cover.jpg"), "image/jpeg")

      update_project(project.id, { cover_image: new_cover, remove_cover_image: "true" }, headers)

      expect(response).to have_http_status(:ok)
      expect(project.reload.cover_image).to be_attached
      expect(project.cover_image.blob).not_to eq(old_blob)
      expect(project.cover_image.content_type).to eq("image/jpeg")
    end

    it "replaces the previous cover image" do
      old_blob = project.cover_image.blob
      new_cover = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/cover.jpg"), "image/jpeg")

      perform_enqueued_jobs { update_project(project.id, { cover_image: new_cover }, headers) }

      expect(response).to have_http_status(:ok)
      expect(project.reload.cover_image.blob).not_to eq(old_blob)
      expect(project.cover_image.content_type).to eq("image/jpeg")
      expect(ActiveStorage::Blob.exists?(old_blob.id)).to be(false)
    end

    it "rejects a cover image larger than 5 MB and keeps the previous one" do
      old_blob = project.cover_image.blob

      update_project(project.id, { cover_image: png_of_size(5.megabytes + 1) }, headers)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("details", "cover_image")).to eq([ I18n.t("activemodel.errors.models.project/update.attributes.cover_image.file_size") ])
      expect(project.reload.cover_image.blob).to eq(old_blob)

      update_project(project.id, { cover_image: png_of_size(5.megabytes) }, headers)

      expect(response).to have_http_status(:ok)
      expect(project.reload.cover_image.content_type).to eq("image/png")
    end

    it "rejects an end date before the start date and keeps the project unchanged" do
      before = stored_state(project)

      update_project(project.id, { end_date: (Date.current + 5.days).iso8601, start_date: (Date.current + 6.days).iso8601 }, headers)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("details", "end_date")).to eq([ I18n.t("activemodel.errors.models.project/update.attributes.end_date.before_start_date") ])
      expect(stored_state(project)).to eq(before)
    end

    it "accepts changing the dates to before today" do
      update_project(project.id, { start_date: (Date.current - 10.days).iso8601, end_date: (Date.current - 1.day).iso8601 }, headers)

      expect(response).to have_http_status(:ok)
      expect(project.reload).to have_attributes(start_date: Date.current - 10.days, end_date: Date.current - 1.day)
    end

    it "rejects a project name with fewer than two words" do
      update_project(project.id, { name: "Website" }, headers)

      expect(response).to have_http_status(:unprocessable_content)
      expect(project.reload.name).to eq("Website Redesign")
    end

    it "answers 422 with the record errors when the record rejects the update" do
      allow_any_instance_of(Project).to receive(:update) do |record|
        record.errors.add(:name, :invalid)
        false
      end

      update_project(project.id, { name: "Mobile App" }, headers)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("details", "name")).to be_present
      expect(project.reload.name).to eq("Website Redesign")
    end

    it "answers 404 for another user's project" do
      update_project(create(:project).id, { name: "Hijacked Project" }, headers)

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when unauthenticated" do
    subject { update_project(project.id, { name: "Mobile App" }, {}) }

    it_behaves_like "an unauthorized API request"
  end
end
