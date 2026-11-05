require "rails_helper"

RSpec.describe UserSession, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  subject(:session) { create(:user_session) }

  describe "associations" do
    it "belongs to a user" do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
      expect(session.user).to be_a(User)
    end
  end

  describe ".revoke_all" do
    it "expires matching sessions without touching other users" do
      freeze_time do
        other_session = create(:user_session, refresh_token_expires_at: 1.hour.from_now)

        session.user.sessions.active.revoke_all

        expect(described_class.active).to contain_exactly(other_session)
        expect(session.reload.refresh_token_expires_at).to eq(1.second.ago)
      end
    end
  end

  describe ".active" do
    it "includes sessions whose refresh_token_expires_at is in the future" do
      active_session = create(:user_session, refresh_token_expires_at: 1.hour.from_now)
      create(:user_session, :expired)

      expect(described_class.active).to contain_exactly(active_session)
    end

    it "includes sessions that expire exactly now" do
      freeze_time do
        borderline_session = create(:user_session, refresh_token_expires_at: Time.current)
        create(:user_session, refresh_token_expires_at: 1.second.ago)

        expect(described_class.active).to contain_exactly(borderline_session)
      end
    end
  end
end
