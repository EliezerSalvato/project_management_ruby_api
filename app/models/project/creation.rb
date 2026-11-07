class Project::Creation < ApplicationForm
  include Project::Validations

  attr_accessor :user, :project

  validates :user, presence: true

  private

  def date_checked?(_field)
    true
  end

  def persist
    attributes = { name:, client_name:, start_date:, end_date: }
    attributes[:cover_image] = cover_image if cover_image.present?

    self.project = user.projects.create(attributes)

    return if project.persisted?

    import_errors(project)
    halt!
  end
end
