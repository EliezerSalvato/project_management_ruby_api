class Project::Update < ApplicationForm
  include Project::Validations

  FIELDS = %w[name client_name start_date end_date cover_image].freeze

  attribute :remove_cover_image, :boolean, default: false

  attr_accessor :project

  before_validation :fill_from_project

  validates :project, presence: true

  def initialize(attributes = {})
    @given_fields = attributes.to_h.keys.map(&:to_s) & FIELDS

    super
  end

  private

  def fill_from_project
    (FIELDS - [ "cover_image" ] - @given_fields).each do |field|
      public_send("#{field}=", project&.public_send(field))
    end
  end

  def date_checked?(field)
    project.present? && @given_fields.include?(field.to_s) && public_send(field) != project.public_send(field)
  end

  def persist
    changes = (@given_fields - [ "cover_image" ]).index_with { |field| public_send(field) }
    if cover_image.present?
      changes["cover_image"] = cover_image
    elsif remove_cover_image
      changes["cover_image"] = nil
    end

    return if project.update(changes)

    import_errors(project)
    halt!
  end
end
