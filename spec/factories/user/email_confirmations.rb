FactoryBot.define do
  factory :user_email_confirmation, class: "UserEmailConfirmation" do
    transient do
      token { nil }
    end

    user
    sequence(:token_digest) { |n| "confirmation-token-digest-#{n}" }
    expires_at { 1.day.from_now }
    new_email { user.email }

    after(:build) do |confirmation, evaluator|
      next if evaluator.token.blank?

      confirmation.token_digest = User::Token.digest(evaluator.token)
    end

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end
  end
end
