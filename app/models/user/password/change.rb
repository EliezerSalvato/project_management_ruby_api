class User::Password::Change < ApplicationForm
  attribute :current_password, :string
  attribute :password, :string
  attribute :password_confirmation, :string

  attr_accessor :user

  with_options presence: true do
    validates :current_password
    validates :user
    validates :password, length: { minimum: User::Password::MIN_LENGTH }, confirmation: true
  end

  private

  def persist
    unless user.authenticate(current_password)
      errors.add(:current_password, :invalid)
      halt!
    end

    if current_password == password
      errors.add(:password, :same_as_current_password)
      halt!
    end

    unless user.update(password:, password_confirmation:)
      import_errors(user)
      halt!
    end

    user.sessions.active.revoke_all
  end
end
