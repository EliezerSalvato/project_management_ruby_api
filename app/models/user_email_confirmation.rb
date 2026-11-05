class UserEmailConfirmation < ApplicationRecord
  belongs_to :user

  scope :not_confirmed, -> { where(confirmed_at: nil) }
  scope :not_expired, -> { where(expires_at: Time.current..) }
  scope :pending, -> { not_confirmed.not_expired }
end
