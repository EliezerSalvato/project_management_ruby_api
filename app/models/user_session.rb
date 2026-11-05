class UserSession < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(refresh_token_expires_at: Time.current..) }

  def self.revoke_all
    update_all(refresh_token_expires_at: 1.second.ago)
  end
end
