class User::Password::Reset::SendInstructions < ApplicationForm
  attribute :email, :string

  attr_accessor :user, :token

  before_validation :normalize_email

  validates :email, presence: true, format: { with: User::Email::FORMAT }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def persist
    self.user = User.find_by(email:)

    if user.blank?
      errors.add(:email, :not_found)
      halt!
    end

    unless user.active?
      errors.add(:base, :user_is_not_active)
      halt!
    end

    unless user.verified?
      errors.add(:base, :user_email_is_not_verified)
      halt!
    end

    user.password_resets.pending.update_all(expires_at: 1.second.ago)

    self.token = user.generate_token_for(:reset_password)

    user.password_resets.create!(
      token_digest: User::Token.digest(token),
      expires_at: User::Password::RESET_TOKEN_EXPIRES_IN.from_now
    )
  end

  def after_persist
    UserMailer.with(email:, token:).password_reset.deliver_later
  end
end
