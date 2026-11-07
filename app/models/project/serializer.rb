class Project::Serializer
  include JSONAPI::Serializer

  set_type :project

  attributes :id, :name, :client_name, :start_date, :end_date, :favorite

  attribute :cover_image_url do |project|
    Rails.application.routes.url_helpers.rails_blob_url(project.cover_image) if project.cover_image.attached?
  end
end
