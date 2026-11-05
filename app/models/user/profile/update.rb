class User::Profile::Update < ApplicationForm
  attribute :first_name, :string
  attribute :last_name, :string

  attr_accessor :user

  before_validation :normalize_names

  validates :user, :first_name, :last_name, presence: true

  private

  def normalize_names
    self.first_name = first_name.to_s.strip
    self.last_name = last_name.to_s.strip
  end

  def persist
    return if user.update(first_name:, last_name:)

    import_errors(user)
    halt!
  end
end
