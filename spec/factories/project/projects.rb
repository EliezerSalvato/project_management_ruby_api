FactoryBot.define do
  factory :project, class: "Project" do
    user
    sequence(:name) { |n| "Project #{n}" }
    client_name { Faker::Company.name }
    start_date { Date.current }
    end_date { Date.current + 30.days }

    trait :with_cover_image do
      cover_image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/cover.png"), "image/png") }
    end
  end
end
