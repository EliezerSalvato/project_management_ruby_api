require "rails_helper"

RSpec.describe Project, type: :model do
  subject(:project) { create(:project) }

  describe "associations" do
    it "belongs to a user" do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
      expect(project.user).to be_a(User)
    end

    it "is destroyed with its user" do
      user = project.user

      expect { user.destroy }.to change(described_class, :count).by(-1)
      expect(User.reflect_on_association(:projects).options).to include(dependent: :destroy)
    end
  end

  describe "database constraints" do
    it "rejects an end date before the start date" do
      expect { project.update_columns(end_date: project.start_date - 1.day) }.to raise_error(ActiveRecord::CheckViolation)
    end
  end
end
