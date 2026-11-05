require "rails_helper"

RSpec.describe User, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  subject(:user) { create(:user) }

  describe "associations" do
    it "has the expected dependent associations" do
      expect(described_class.reflect_on_association(:sessions).options)
        .to include(class_name: "UserSession", dependent: :destroy)
      expect(described_class.reflect_on_association(:email_confirmations).options)
        .to include(class_name: "UserEmailConfirmation", dependent: :destroy)
      expect(described_class.reflect_on_association(:password_resets).options)
        .to include(class_name: "UserPasswordReset", dependent: :destroy)
    end

    it "destroys associated records with the user" do
      session = UserSession.create!(
        user: user,
        refresh_token_digest: "session-token",
        refresh_token_expires_at: 1.day.from_now
      )
      confirmation = UserEmailConfirmation.create!(
        user: user,
        token_digest: "confirmation-token",
        expires_at: 1.day.from_now
      )
      password_reset = UserPasswordReset.create!(
        user: user,
        token_digest: "reset-token",
        expires_at: 1.day.from_now
      )

      user.destroy!

      expect(UserSession.exists?(session.id)).to be(false)
      expect(UserEmailConfirmation.exists?(confirmation.id)).to be(false)
      expect(UserPasswordReset.exists?(password_reset.id)).to be(false)
    end
  end

  describe "password authentication" do
    it "stores a password digest and authenticates the correct password" do
      expect(user.password_digest).to be_present
      expect(user.authenticate("password123")).to eq(user)
    end

    it "rejects an incorrect password" do
      expect(user.authenticate("incorrect-password")).to be(false)
    end
  end

  describe "reset password token" do
    it "finds the user from a valid token" do
      token = user.generate_token_for(:reset_password)

      expect(described_class.find_by_token_for(:reset_password, token)).to eq(user)
    end

    it "invalidates the token when the password changes" do
      token = user.generate_token_for(:reset_password)

      user.update!(password: "new-password123", password_confirmation: "new-password123")

      expect(described_class.find_by_token_for(:reset_password, token)).to be_nil
    end

    it "expires the token after the configured duration" do
      token = user.generate_token_for(:reset_password)

      travel User::Password::RESET_TOKEN_EXPIRES_IN + 1.second

      expect(described_class.find_by_token_for(:reset_password, token)).to be_nil
    end
  end

  describe "email confirmation token" do
    it "finds the user from a valid token" do
      token = user.generate_token_for(:email_confirmation)

      expect(described_class.find_by_token_for(:email_confirmation, token)).to eq(user)
    end

    it "invalidates the token when the email changes" do
      token = user.generate_token_for(:email_confirmation)

      user.update!(email: "new-email@example.com")

      expect(described_class.find_by_token_for(:email_confirmation, token)).to be_nil
    end

    it "invalidates the token when the verification status changes" do
      token = user.generate_token_for(:email_confirmation)

      user.update!(verified: true)

      expect(described_class.find_by_token_for(:email_confirmation, token)).to be_nil
    end

    it "expires the token after the configured duration" do
      token = user.generate_token_for(:email_confirmation)

      travel User::Email::CONFIRMATION_TOKEN_EXPIRES_IN + 1.second

      expect(described_class.find_by_token_for(:email_confirmation, token)).to be_nil
    end
  end
end
