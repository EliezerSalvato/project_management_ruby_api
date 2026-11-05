class User::Registration < ApplicationForm
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :email, :string
  attribute :password, :string
  attribute :password_confirmation, :string

  attr_accessor :user, :token

  before_validation :normalize_attributes

  with_options presence: true do
    validates :first_name, :last_name
    validates :email, format: { with: User::Email::FORMAT }
    validates :password, length: { minimum: User::Password::MIN_LENGTH }, confirmation: true
  end

  private

  def normalize_attributes
    self.first_name = first_name.to_s.strip
    self.last_name = last_name.to_s.strip
    self.email = email.to_s.strip.downcase
  end

  def persist
    if User.exists?(email:)
      errors.add(:email, :taken)
      halt!
    end

    self.user = User.create(first_name:, last_name:, email:, password:, password_confirmation:)

    unless user.persisted?
      import_errors(user)
      halt!
    end

    self.token = user.generate_token_for(:email_confirmation)

    user.email_confirmations.create!(
      token_digest: User::Token.digest(token),
      new_email: user.email,
      expires_at: User::Email::CONFIRMATION_TOKEN_EXPIRES_IN.from_now
    )
  end

  def after_persist
    UserMailer.with(email: user.email, token:).email_verification.deliver_later
  end
end
