class User::Email::Confirmation < ApplicationForm
  attribute :token, :string

  attr_accessor :user

  validates :token, presence: true

  private

  def persist
    self.user = User.find_by_token_for(:email_confirmation, token)

    if user.blank?
      errors.add(:base, :invalid_token)
      halt!
    end

    confirmation = user.email_confirmations.pending.find_by(token_digest: User::Token.digest(token))

    if confirmation.blank?
      errors.add(:base, :invalid_token)
      halt!
    end

    apply_pending_email_change(confirmation)
    user.update!(verified: true)
    confirmation.update!(confirmed_at: Time.current)
    user.sessions.active.revoke_all
  end

  def apply_pending_email_change(confirmation)
    pending_email = confirmation.new_email
    return if pending_email.blank? || pending_email == user.email

    if User.where.not(id: user.id).exists?(email: pending_email)
      errors.add(:base, :email_taken)
      halt!
    end

    user.update!(email: pending_email)
  end
end
