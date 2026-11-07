require "rails_helper"

RSpec.describe "POST /api/v1/projects", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, :verified) }
  let(:headers) { auth_headers_for(user) }
  let(:valid_params) do
    {
      name: "Website Redesign",
      client_name: "Acme Corp",
      start_date: Date.current.iso8601,
      end_date: (Date.current + 10.days).iso8601
    }
  end

  def create_project(params, headers)
    post "/api/v1/projects", params: params, headers: headers
  end

  def project_attributes
    response.parsed_body.dig("data", "project", "data", "attributes")
  end

  def upload(path, content_type)
    Rack::Test::UploadedFile.new(path, content_type)
  end

  def fixture_path(name)
    Rails.root.join("spec/fixtures/files", name)
  end

  def file_with(bytes, name)
    file = Tempfile.new([ File.basename(name, ".*"), File.extname(name) ])
    file.binmode
    file.write(bytes)
    file.rewind
    file
  end

  def png_of_size(size)
    header = File.binread(fixture_path("cover.png"))
    file_with(header + ("\0" * (size - header.bytesize)), "big.png")
  end

  context "when authenticated" do
    it "creates the project owned by the current user with favorite false" do
      expect { create_project(valid_params, headers) }.to change(user.projects, :count).by(1)

      project = user.projects.last

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("success")
      expect(response.parsed_body["message"]).to eq(I18n.t("project.creation.success"))
      expect(project).to have_attributes(
        name: "Website Redesign",
        client_name: "Acme Corp",
        start_date: Date.current,
        end_date: Date.current + 10.days,
        favorite: false
      )
      expect(project_attributes).to include(
        "id" => project.id,
        "name" => "Website Redesign",
        "client_name" => "Acme Corp",
        "start_date" => Date.current.iso8601,
        "end_date" => (Date.current + 10.days).iso8601,
        "favorite" => false,
        "cover_image_url" => nil
      )
    end

    it "stores a JPEG or PNG cover image and returns a URL that serves it" do
      { "cover.png" => "image/png", "cover.jpg" => "image/jpeg" }.each do |name, content_type|
        create_project(valid_params.merge(cover_image: upload(fixture_path(name), content_type)), headers)

        expect(response).to have_http_status(:created)

        project = user.projects.find(project_attributes["id"])

        expect(project.cover_image).to be_attached
        expect(project.cover_image.content_type).to eq(content_type)

        get project_attributes["cover_image_url"]
        follow_redirect! while response.redirect?

        expect(response).to have_http_status(:ok)
        expect(response.body.b).to eq(File.binread(fixture_path(name)))
      end
    end

    it "rejects a request missing name, client name, start date and end date with an error on each" do
      expect { create_project({ name: "" }, headers) }.not_to change(Project, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["status"]).to eq("error")
      expect(response.parsed_body["details"].keys).to include("name", "client_name", "start_date", "end_date")
    end

    it "rejects a date that is not a valid date" do
      expect { create_project(valid_params.merge(start_date: "2026-13-45"), headers) }.not_to change(Project, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("details", "start_date")).to be_present
    end

    it "rejects an end date before the start date" do
      params = valid_params.merge(start_date: (Date.current + 5.days).iso8601, end_date: (Date.current + 4.days).iso8601)

      expect { create_project(params, headers) }.not_to change(Project, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("details", "end_date")).to eq([ I18n.t("activemodel.errors.models.project/creation.attributes.end_date.before_start_date") ])
    end

    it "rejects a cover image that is neither JPEG nor PNG" do
      gif = upload(fixture_path("cover.gif"), "image/gif")
      text_as_png = upload(file_with("not an image", "fake.png").path, "image/png")

      [ gif, text_as_png ].each do |cover_image|
        expect { create_project(valid_params.merge(cover_image:), headers) }.not_to change(Project, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.dig("details", "cover_image")).to eq([ I18n.t("activemodel.errors.models.project/creation.attributes.cover_image.content_type") ])
      end
    end

    it "rejects a cover image larger than 5 MB" do
      too_big = upload(png_of_size(5.megabytes + 1).path, "image/png")

      expect { create_project(valid_params.merge(cover_image: too_big), headers) }.not_to change(Project, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("details", "cover_image")).to eq([ I18n.t("activemodel.errors.models.project/creation.attributes.cover_image.file_size") ])

      create_project(valid_params.merge(cover_image: upload(png_of_size(5.megabytes).path, "image/png")), headers)

      expect(response).to have_http_status(:created)
    end

    it "rejects a name or client name longer than 255 characters" do
      long_name = "Project #{"a" * 248}"

      %i[name client_name].each do |field|
        expect { create_project(valid_params.merge(field => long_name), headers) }.not_to change(Project, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.dig("details", field.to_s)).to be_present
      end

      create_project(valid_params.merge(name: long_name.chop, client_name: long_name.chop), headers)

      expect(response).to have_http_status(:created)
    end

    it "ignores favorite sent on create" do
      create_project(valid_params.merge(favorite: true), headers)

      expect(response).to have_http_status(:created)
      expect(project_attributes["favorite"]).to be(false)
      expect(user.projects.last.favorite).to be(false)
    end

    it "ignores remove_cover_image sent on create" do
      create_project(valid_params.merge(cover_image: upload(fixture_path("cover.png"), "image/png"), remove_cover_image: "true"), headers)

      expect(response).to have_http_status(:created)
      expect(user.projects.find(project_attributes["id"]).cover_image).to be_attached
    end

    it "strips surrounding spaces from name and client name" do
      create_project(valid_params.merge(name: "  Website Redesign  ", client_name: "  Acme Corp  "), headers)

      expect(response).to have_http_status(:created)
      expect(user.projects.last).to have_attributes(name: "Website Redesign", client_name: "Acme Corp")
    end

    it "rejects a project name with fewer than two words" do
      [ "Website", "  Website  ", "\u00A0Website\u00A0" ].each do |name|
        expect { create_project(valid_params.merge(name:), headers) }.not_to change(Project, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.dig("details", "name")).to eq([ I18n.t("activemodel.errors.models.project/creation.attributes.name.two_words") ])
      end
    end

    it "treats non-ASCII spaces as word separators and strips them" do
      create_project(valid_params.merge(name: "\u00A0Website\u00A0Redesign\u2003", client_name: "\u00A0Acme Corp\u00A0"), headers)

      expect(response).to have_http_status(:created)
      expect(user.projects.last).to have_attributes(name: "Website\u00A0Redesign", client_name: "Acme Corp")
    end

    it "rejects a start date before today" do
      expect { create_project(valid_params.merge(start_date: (Date.current - 1.day).iso8601), headers) }.not_to change(Project, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("details", "start_date")).to eq([ I18n.t("activemodel.errors.models.project/creation.attributes.start_date.before_today") ])
    end

    it "rejects an end date before today" do
      params = valid_params.merge(start_date: Date.current.iso8601, end_date: (Date.current - 1.day).iso8601)

      expect { create_project(params, headers) }.not_to change(Project, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("details", "end_date")).to include(I18n.t("activemodel.errors.models.project/creation.attributes.end_date.before_today"))
    end

    it "accepts start and end dates equal to today" do
      params = valid_params.merge(start_date: Date.current.iso8601, end_date: Date.current.iso8601)

      expect { create_project(params, headers) }.to change(Project, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "uses today in America/Sao_Paulo" do
      travel_to Time.utc(2026, 11, 6, 1, 0, 0) do
        headers = auth_headers_for(user)

        create_project(valid_params.merge(start_date: "2026-11-05", end_date: "2026-11-05"), headers)

        expect(response).to have_http_status(:created)

        create_project(valid_params.merge(start_date: "2026-11-04", end_date: "2026-11-05"), headers)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.dig("details", "start_date")).to be_present
      end
    end
  end

  context "when unauthenticated" do
    subject { create_project(valid_params, {}) }

    it_behaves_like "an unauthorized API request"
  end

  context "with an invalid bearer token" do
    subject { create_project(valid_params, { "Authorization" => "Bearer invalid-token" }) }

    it_behaves_like "an unauthorized API request"
  end
end
