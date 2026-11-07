require "rails_helper"

RSpec.describe "GET /api/v1/projects", type: :request do
  let(:user) { create(:user, :verified) }
  let(:headers) { auth_headers_for(user) }

  def list_projects(params, headers)
    get "/api/v1/projects", params: params, headers: headers
  end

  def listed_names
    response.parsed_body.dig("data", "projects", "data").map { |project| project.dig("attributes", "name") }
  end

  def listed_ids
    response.parsed_body.dig("data", "projects", "data").map { |project| project.dig("attributes", "id") }
  end

  def pagination
    response.parsed_body.dig("data", "pagination")
  end

  context "when authenticated" do
    it "returns only the current user's projects" do
      own = create_list(:project, 2, user:)
      create(:project, name: "Foreign Project")

      list_projects({}, headers)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("success")
      expect(listed_ids).to match_array(own.map(&:id))
    end

    it "orders by name ascending ignoring case by default" do
      # "Alpha App" and "alpha app" only differ by case: compared in lowercase they tie,
      # so the id (creation order) decides - a case-sensitive collation would not.
      [ "beta App", "Alpha App", "alpha app", "Charlie App" ].each { |name| create(:project, user:, name:) }

      list_projects({}, headers)

      expect(listed_names).to eq([ "Alpha App", "alpha app", "beta App", "Charlie App" ])
    end

    it "orders by start date descending with sort=recent_start" do
      create(:project, user:, name: "Ten Days", start_date: Date.current - 10.days)
      create(:project, user:, name: "Two Days", start_date: Date.current - 2.days)
      create(:project, user:, name: "Five Days", start_date: Date.current - 5.days)

      list_projects({ sort: "recent_start" }, headers)

      expect(listed_names).to eq([ "Two Days", "Five Days", "Ten Days" ])
    end

    it "lists started projects first, then upcoming ones soonest first, then overdue ones with sort=recent_start" do
      today = Date.current
      create(:project, user:, name: "Starts In Ten", start_date: today + 10.days, end_date: today + 20.days)
      create(:project, user:, name: "Started Ten Ago", start_date: today - 10.days)
      create(:project, user:, name: "Overdue Recent", start_date: today - 2.days, end_date: today - 1.day)
      create(:project, user:, name: "Starts Tomorrow", start_date: today + 1.day, end_date: today + 20.days)
      create(:project, user:, name: "Started Today", start_date: today)
      create(:project, user:, name: "Overdue Old", start_date: today - 9.days, end_date: today - 3.days)
      create(:project, user:, name: "Due Today", start_date: today - 5.days, end_date: today)

      list_projects({ sort: "recent_start" }, headers)

      expect(listed_names).to eq(
        [ "Started Today", "Due Today", "Started Ten Ago", "Starts Tomorrow", "Starts In Ten", "Overdue Recent", "Overdue Old" ]
      )
    end

    it "orders by end date ascending with overdue projects last with sort=nearest_deadline" do
      create(:project, user:, name: "Ten Days", end_date: Date.current + 10.days)
      create(:project, user:, name: "Overdue Project", start_date: Date.current - 20.days, end_date: Date.current - 3.days)
      create(:project, user:, name: "Due Today", start_date: Date.current - 20.days, end_date: Date.current)
      create(:project, user:, name: "Two Days", end_date: Date.current + 2.days)

      list_projects({ sort: "nearest_deadline" }, headers)

      expect(listed_names).to eq([ "Due Today", "Two Days", "Ten Days", "Overdue Project" ])
    end

    it "breaks ties by name then id" do
      deadline = Date.current + 7.days
      create(:project, user:, name: "Charlie One", end_date: deadline)
      create(:project, user:, name: "alpha Two", end_date: deadline)
      twins = create_list(:project, 2, user:, name: "Same Name", end_date: deadline)

      list_projects({ sort: "nearest_deadline" }, headers)

      expect(listed_names).to eq([ "alpha Two", "Charlie One", "Same Name", "Same Name" ])
      expect(listed_ids.last(2)).to eq(twins.map(&:id).sort)
    end

    it "rejects an unknown sort value" do
      list_projects({ sort: "oldest" }, headers)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["status"]).to eq("error")
      expect(response.parsed_body.dig("details", "sort")).to be_present
    end

    it "lists only favorite projects with favorite=true and only the others with favorite=false" do
      favorites = create_list(:project, 2, user:, favorite: true)
      others = create_list(:project, 2, user:, favorite: false)
      create(:project, favorite: true)

      list_projects({ favorite: "true" }, headers)

      expect(response).to have_http_status(:ok)
      expect(listed_ids).to match_array(favorites.map(&:id))
      expect(pagination).to include("count" => 2)

      list_projects({ favorite: "false" }, headers)

      expect(listed_ids).to match_array(others.map(&:id))

      list_projects({ favorite: "" }, headers)

      expect(listed_ids).to match_array((favorites + others).map(&:id))
    end

    it "combines the favorite filter with search and sort" do
      create(:project, user:, name: "Zeta Website", favorite: true)
      create(:project, user:, name: "Alpha Website", favorite: true)
      create(:project, user:, name: "Beta Website", favorite: false)
      create(:project, user:, name: "Gamma Mobile", favorite: true)

      list_projects({ favorite: "true", search: "website" }, headers)

      expect(listed_names).to eq([ "Alpha Website", "Zeta Website" ])
    end

    it "rejects a favorite value other than true or false" do
      [ "yes", "1", "TRUE" ].each do |favorite|
        list_projects({ favorite: }, headers)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["status"]).to eq("error")
        expect(response.parsed_body.dig("details", "favorite")).to be_present
      end
    end

    context "with 21 projects" do
      let!(:projects) do
        (1..21).map { |n| create(:project, user:, name: format("Project %02d", n)) }
      end

      it "returns at most 20 projects and the id of the last one as next" do
        list_projects({}, headers)

        expect(listed_names).to eq((1..20).map { |n| format("Project %02d", n) })
        expect(pagination).to eq("next" => projects[19].id, "count" => 21, "limit" => 20)
      end

      it "returns the projects after the given id and no next on the last page" do
        list_projects({ after: projects[19].id }, headers)

        expect(listed_names).to eq([ "Project 21" ])
        expect(pagination).to eq("next" => nil, "count" => 21, "limit" => 20)
      end

      it "returns an empty list after the last project" do
        list_projects({ after: projects.last.id }, headers)

        expect(response).to have_http_status(:ok)
        expect(listed_names).to eq([])
        expect(pagination).to eq("next" => nil, "count" => 21, "limit" => 20)
      end

      it "loads every project exactly once when following next" do
        names = []
        params = {}

        loop do
          list_projects(params, headers)
          names.concat(listed_names)
          break unless pagination["next"]

          params = { after: pagination["next"] }
        end

        expect(names).to eq((1..21).map { |n| format("Project %02d", n) })
      end

      it "neither repeats nor skips projects when one is created before the cursor while scrolling" do
        list_projects({}, headers)
        cursor = pagination["next"]

        create(:project, user:, name: "Project 00")
        list_projects({ after: cursor }, headers)

        expect(listed_names).to eq([ "Project 21" ])
      end
    end

    it "pages after the cursor in every sort order" do
      base = Date.current
      projects = [
        create(:project, user:, name: "Delta App", start_date: base - 1.day, end_date: base + 1.day),
        create(:project, user:, name: "alpha App", start_date: base - 3.days, end_date: base + 5.days),
        create(:project, user:, name: "Bravo App", start_date: base - 3.days, end_date: base + 5.days),
        create(:project, user:, name: "Charlie App", start_date: base - 5.days, end_date: base + 9.days),
        create(:project, user:, name: "Echo App", start_date: base - 4.days, end_date: base - 2.days),
        create(:project, user:, name: "Foxtrot App", start_date: base - 6.days, end_date: base - 1.day),
        create(:project, user:, name: "Golf App", start_date: base + 4.days, end_date: base + 12.days),
        create(:project, user:, name: "Hotel App", start_date: base + 2.days, end_date: base + 12.days)
      ]
      stub_const("Project::Search::PER_PAGE", 1)

      {
        "name" => [ 1, 2, 3, 0, 4, 5, 6, 7 ],
        "recent_start" => [ 0, 1, 2, 3, 7, 6, 4, 5 ],
        "nearest_deadline" => [ 0, 1, 2, 3, 6, 7, 4, 5 ]
      }.each do |sort, order|
        expected = order.map { |index| projects[index].name }
        names = []
        params = { sort: }

        loop do
          list_projects(params, headers)
          names.concat(listed_names)
          break unless pagination["next"]

          params = { sort:, after: pagination["next"] }
        end

        expect(names).to eq(expected), "sort=#{sort}: #{names.inspect}"
      end
    end

    it "applies the cursor together with search and favorite filters" do
      first = create(:project, user:, name: "Alpha Website", favorite: true)
      create(:project, user:, name: "Beta Website", favorite: false)
      create(:project, user:, name: "Gamma Website", favorite: true)
      create(:project, user:, name: "Delta Mobile", favorite: true)

      list_projects({ search: "website", favorite: "true", after: first.id }, headers)

      expect(listed_names).to eq([ "Gamma Website" ])
      expect(pagination).to include("count" => 2)
    end

    it "rejects an after id that is not one of the user's projects" do
      foreign = create(:project)

      [ foreign.id, "not-a-uuid", SecureRandom.uuid ].each do |after|
        list_projects({ after: }, headers)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["status"]).to eq("error")
        expect(response.parsed_body.dig("details", "after")).to be_present
      end
    end

    it "returns an empty list when the user has no projects" do
      list_projects({}, headers)

      expect(response).to have_http_status(:ok)
      expect(listed_names).to eq([])
      expect(pagination).to eq("next" => nil, "count" => 0, "limit" => 20)
    end
  end

  context "when unauthenticated" do
    subject { list_projects({}, {}) }

    it_behaves_like "an unauthorized API request"
  end
end
