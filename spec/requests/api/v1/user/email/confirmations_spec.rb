require "rails_helper"

RSpec.describe "API::V1::User::Email::Confirmations", type: :request do
  describe "POST /api/v1/user/email/confirmations" do
    let(:user) { create(:user) }
    let(:token) { user.generate_token_for(:email_confirmation) }
    let!(:confirmation) { create(:user_email_confirmation, user:, token:) }

    def post_confirmation(params)
      post "/api/v1/user/email/confirmations", params: params, as: :json
    end

    context "with a valid token" do
      it "confirms the email and marks the confirmation as confirmed" do
        post_confirmation(token: token)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["status"]).to eq("success")
        expect(response.parsed_body["message"]).to eq(I18n.t("user.email.confirmation.success"))
        expect(user.reload).to be_verified
        expect(confirmation.reload.confirmed_at).to be_present
      end
    end

    context "when confirming an email change" do
      let(:user) { create(:user, :verified, email: "old.email@example.com") }
      let!(:confirmation) do
        create(
          :user_email_confirmation,
          user:,
          token:,
          old_email: user.email,
          new_email: "new.email@example.com"
        )
      end

      it "applies the new email and keeps the user verified" do
        post_confirmation(token: token)

        expect(response).to have_http_status(:ok)
        expect(user.reload).to have_attributes(email: "new.email@example.com", verified: true)
        expect(confirmation.reload.confirmed_at).to be_present
      end

      it "revokes the active sessions" do
        create(:user_session, user:)

        post_confirmation(token: token)

        expect(UserSession.active.where(user_id: user.id)).to be_empty
      end
    end

    context "when the new email was taken before confirmation" do
      let(:user) { create(:user, :verified, email: "old.email@example.com") }
      let!(:confirmation) do
        create(
          :user_email_confirmation,
          user:,
          token:,
          old_email: user.email,
          new_email: "taken@example.com"
        )
      end

      before { create(:user, email: "taken@example.com") }

      it "does not change the email" do
        session = create(:user_session, user:)

        post_confirmation(token: token)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.dig("details", "base")).to eq([ "Email has already been taken" ])
        expect(user.reload).to have_attributes(email: "old.email@example.com", verified: true)
        expect(confirmation.reload.confirmed_at).to be_nil
        expect(UserSession.active.where(user_id: user.id)).to include(session)
      end
    end

    context "with an invalid token" do
      it "does not verify the user" do
        post_confirmation(token: "invalid-token")

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["status"]).to eq("error")
        expect(response.parsed_body.dig("details", "base")).to eq([ "Token is invalid" ])
        expect(user.reload).not_to be_verified
      end
    end

    context "with an expired token" do
      let!(:confirmation) { create(:user_email_confirmation, :expired, user:, token:) }

      it "returns 422 unprocessable entity" do
        post_confirmation(token: token)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.dig("details", "base")).to eq([ "Token is invalid" ])
        expect(user.reload).not_to be_verified
      end
    end

    context "with an already confirmed token" do
      let!(:confirmation) { create(:user_email_confirmation, :confirmed, user:, token:) }

      it "returns 422 unprocessable entity" do
        post_confirmation(token: token)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.dig("details", "base")).to eq([ "Token is invalid" ])
      end
    end

    context "with a blank token" do
      it "returns 422 unprocessable entity" do
        post_confirmation(token: "")

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.dig("details", "token")).to be_present
      end
    end
  end
end
