class User::Authentication < ApplicationForm
  attribute :email, :string
  attribute :password, :string
  attribute :remember_me, :boolean, default: false
  attribute :ip_address, :string
  attribute :user_agent, :string

  attr_accessor :user, :token, :refresh_token

  before_validation :normalize_email

  validates :email, :password, presence: true

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def persist
    self.user = User.authenticate_by(email:, password:)

    if user.blank?
      errors.add(:base, :invalid_email_or_password)
      halt!
    end

    # unless user.verified?
    #   errors.add(:base, :user_email_is_not_verified)
    #   halt!
    # end

    unless user.active?
      errors.add(:base, :user_is_not_active)
      halt!
    end

    user.sessions.active.revoke_all

    self.refresh_token = User::Token.generate

    user.sessions.create!(
      refresh_token_digest: User::Token.digest(refresh_token),
      refresh_token_expires_at: User::Token.refresh_token_expires_in(remember_me:).from_now,
      user_agent:,
      ip_address:
    )

    self.token = user.signed_id(purpose: :session_token, expires_in: User::Token::SESSION_TOKEN_EXPIRES_IN)
  end
end
