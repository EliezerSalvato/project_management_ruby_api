class User::Account::Deletion < ApplicationForm
  attribute :password, :string

  attr_accessor :user

  validates :user, :password, presence: true

  private

  def persist
    if user.authenticate(password)
      user.destroy!
      return
    end

    errors.add(:password, :invalid)
    halt!
  end
end
