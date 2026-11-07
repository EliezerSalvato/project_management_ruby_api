require "rails_helper"

# Endpoints always pass a project (unknown ids answer 404 first); this covers the form's own guard.
RSpec.describe Project::Update do
  it "is invalid without a project instead of raising" do
    update = described_class.new(name: "Website Redesign")

    expect(update.save).to be(false)
    expect(update.errors).to be_added(:project, :blank)
  end
end
