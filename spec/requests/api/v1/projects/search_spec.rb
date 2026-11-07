require "rails_helper"

RSpec.describe "GET /api/v1/projects with search", type: :request do
  let(:user) { create(:user, :verified) }
  let(:headers) { auth_headers_for(user) }

  def list_projects(params)
    get "/api/v1/projects", params: params, headers: headers
  end

  def listed_names
    response.parsed_body.dig("data", "projects", "data").map { |project| project.dig("attributes", "name") }
  end

  it "returns projects whose name or client name contains the term" do
    create(:project, user:, name: "Website Redesign", client_name: "Acme Corp")
    create(:project, user:, name: "Acme Portal", client_name: "Globex")
    create(:project, user:, name: "Mobile App", client_name: "Initech")
    create(:project, name: "Acme Foreign", client_name: "Acme Corp")

    list_projects({ search: "acm" })

    expect(response).to have_http_status(:ok)
    expect(listed_names).to contain_exactly("Website Redesign", "Acme Portal")
  end

  it "matches ignoring letter case" do
    create(:project, user:, name: "Website Redesign", client_name: "acme corp")
    create(:project, user:, name: "Mobile App", client_name: "Initech")

    list_projects({ search: "ACME" })

    expect(listed_names).to eq([ "Website Redesign" ])
  end

  it "matches ignoring accents" do
    create(:project, user:, name: "Club Website", client_name: "São Paulo FC")
    create(:project, user:, name: "Cafe Mobile", client_name: "Initech")
    create(:project, user:, name: "Other Project", client_name: "Globex")

    list_projects({ search: "sao" })

    expect(listed_names).to eq([ "Club Website" ])

    list_projects({ search: "café" })

    expect(listed_names).to eq([ "Cafe Mobile" ])
  end

  it "rejects a search with fewer than 3 characters" do
    create(:project, user:, client_name: "Acme Corp")

    [ "ac", "  ac  ", "a", "ac\u00A0", "\u2003ac" ].each do |search|
      list_projects({ search: })

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["status"]).to eq("error")
      expect(response.parsed_body.dig("details", "search")).to be_present
    end
  end

  it "returns every project when search is blank" do
    projects = create_list(:project, 3, user:)

    [ "", "   " ].each do |search|
      list_projects({ search: })

      expect(response).to have_http_status(:ok)
      expect(listed_names).to match_array(projects.map(&:name))
    end
  end

  it "returns the filtered projects in the chosen order" do
    create(:project, user:, name: "Acme Later", end_date: Date.current + 20.days)
    create(:project, user:, name: "Acme Sooner", end_date: Date.current + 2.days)
    create(:project, user:, name: "Other Soonest", end_date: Date.current + 1.day)

    list_projects({ search: "acme", sort: "nearest_deadline" })

    expect(listed_names).to eq([ "Acme Sooner", "Acme Later" ])
  end

  it "treats % and _ as literal characters" do
    create(:project, user:, name: "Sale 50% Off")
    create(:project, user:, name: "Sale 500 Off")
    create(:project, user:, name: "a_b App")
    create(:project, user:, name: "axb App")

    list_projects({ search: "50%" })

    expect(listed_names).to eq([ "Sale 50% Off" ])

    list_projects({ search: "a_b" })

    expect(listed_names).to eq([ "a_b App" ])
  end
end
