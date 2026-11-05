class User::Password::Reset < ApplicationForm
  attribute :token, :string
  attribute :password, :string
  attribute :password_confirmation, :string

  attr_accessor :user

  with_options presence: true do
    validates :token
    validates :password, length: { minimum: User::Password::MIN_LENGTH }, confirmation: true
  end

  private

  def persist
    self.user = User.find_by_token_for(:reset_password, token)

    if user.blank?
      errors.add(:base, :invalid_token)
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

    password_reset = user.password_resets.pending.find_by(token_digest: User::Token.digest(token))

    if password_reset.blank?
      errors.add(:base, :invalid_token)
      halt!
    end

    if user.authenticate(password)
      errors.add(:password, :same_as_current_password)
      halt!
    end

    unless user.update(password:, password_confirmation:)
      import_errors(user)
      halt!
    end

    password_reset.update!(reset_at: Time.current)
    user.sessions.active.revoke_all
  end
end
