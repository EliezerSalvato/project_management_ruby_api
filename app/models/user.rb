class User < ApplicationRecord
  has_many :sessions, class_name: "UserSession", dependent: :destroy
  has_many :email_confirmations, class_name: "UserEmailConfirmation", dependent: :destroy
  has_many :password_resets, class_name: "UserPasswordReset", dependent: :destroy

  has_secure_password

  generates_token_for :reset_password, expires_in: User::Password::RESET_TOKEN_EXPIRES_IN do
    password_salt&.last(10)
  end

  generates_token_for :email_confirmation, expires_in: User::Email::CONFIRMATION_TOKEN_EXPIRES_IN do
    [ email, verified ]
  end
end
