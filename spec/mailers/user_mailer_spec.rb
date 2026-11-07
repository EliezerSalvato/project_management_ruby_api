require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("FRONTEND_URL").and_return("https://app.example.com/")
  end

  describe "#email_verification" do
    let(:mail) { described_class.with(email: "user@example.com", token: "confirm-token").email_verification }

    it "sends the confirmation link to the user" do
      expect(mail.to).to eq([ "user@example.com" ])
      expect(mail.subject).to eq(I18n.t("mailer.user.email.confirmation.subject"))
      expect(mail.body.encoded).to include("https://app.example.com/users/confirmation?token=confirm-token")
    end
  end

  describe "#password_reset" do
    let(:mail) { described_class.with(email: "user@example.com", token: "reset-token").password_reset }

    it "sends the password reset link to the user" do
      expect(mail.to).to eq([ "user@example.com" ])
      expect(mail.subject).to eq(I18n.t("mailer.user.password_reset.subject"))
      expect(mail.body.encoded).to include("https://app.example.com/users/password/edit?token=reset-token")
    end
  end
end
