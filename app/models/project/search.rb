class Project::Search < ApplicationForm
  PER_PAGE = 20
  FAVORITE_VALUES = %w[true false].freeze

  attribute :search, :string
  attribute :sort, :string
  attribute :favorite, :string
  attribute :after, :string

  attr_accessor :user

  before_validation :normalize_search, :normalize_sort

  validates :user, presence: true
  validates :search, length: { minimum: 3 }, allow_blank: true
  validates :sort, inclusion: { in: Project::Sort::KEYS.keys }
  validates :favorite, inclusion: { in: FAVORITE_VALUES }, allow_blank: true
  validate :cursor_must_exist, if: -> { after.present? }

  def projects
    page.first(PER_PAGE)
  end

  def count
    @count ||= filtered.count
  end

  def next_cursor
    projects.last.id if page.size > PER_PAGE
  end

  private

  def page
    @page ||= results.limit(PER_PAGE + 1).to_a
  end

  def results
    today = Date.current

    projects = filtered.with_attached_cover_image.sorted_by(sort, today:)
    projects = projects.after_cursor(cursor.id, sort, today:) if cursor
    projects
  end

  def filtered
    projects = user.projects
    projects = projects.search(search) if search.present?
    projects = projects.where(favorite: favorite == "true") if favorite.present?
    projects
  end

  def cursor
    return @cursor if defined?(@cursor)

    @cursor = after.present? ? user.projects.find_by(id: after) : nil
  end

  def cursor_must_exist
    errors.add(:after, :not_found) if user && cursor.nil?
  end

  def normalize_search
    self.search = Project::Text.strip(search)
  end

  def normalize_sort
    self.sort = sort.presence || Project::Sort::DEFAULT
  end
end
