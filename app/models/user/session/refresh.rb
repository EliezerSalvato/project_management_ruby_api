class User::Session::Refresh < ApplicationForm
  attribute :refresh_token, :string
  attribute :remember_me, :boolean, default: false

  attr_accessor :user, :token

  validates :refresh_token, presence: true

  private

  def persist
    incoming_token = refresh_token
    session = UserSession.active.eager_load(:user).find_by(refresh_token_digest: User::Token.digest(incoming_token))

    if session.blank?
      errors.add(:base, :invalid_refresh_token)
      halt!
    end

    self.user = session.user

    unless user.active?
      errors.add(:base, :user_is_not_active)
      halt!
    end

    self.refresh_token = User::Token.generate

    session.update!(
      refresh_token_digest: User::Token.digest(refresh_token),
      refresh_token_expires_at: User::Token.refresh_token_expires_in(remember_me:).from_now
    )

    self.token = user.signed_id(purpose: :session_token, expires_in: User::Token::SESSION_TOKEN_EXPIRES_IN)
  end
end
