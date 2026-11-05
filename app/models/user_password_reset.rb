class UserPasswordReset < ApplicationRecord
  belongs_to :user

  scope :not_reset, -> { where(reset_at: nil) }
  scope :not_expired, -> { where(expires_at: Time.current..) }
  scope :pending, -> { not_reset.not_expired }
end
