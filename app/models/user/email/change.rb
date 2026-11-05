class User::Email::Change < ApplicationForm
  attribute :current_password, :string
  attribute :new_email, :string

  attr_accessor :user, :token

  before_validation :normalize_new_email

  with_options presence: true do
    validates :current_password
    validates :user
    validates :new_email, format: { with: User::Email::FORMAT }
  end

  private

  def normalize_new_email
    self.new_email = new_email.to_s.strip.downcase
  end

  def persist
    unless user.authenticate(current_password)
      errors.add(:current_password, :invalid)
      halt!
    end

    if user.email == new_email
      errors.add(:base, :new_email_is_the_same_as_the_current_email)
      halt!
    end

    if User.exists?(email: new_email)
      errors.add(:new_email, :taken)
      halt!
    end

    user.email_confirmations.pending.update_all(expires_at: 1.second.ago)

    self.token = user.generate_token_for(:email_confirmation)

    user.email_confirmations.create!(
      token_digest: User::Token.digest(token),
      old_email: user.email,
      new_email:,
      expires_at: User::Email::CONFIRMATION_TOKEN_EXPIRES_IN.from_now
    )
  end

  def after_persist
    UserMailer.with(email: new_email, token:).email_verification.deliver_later
  end
end
