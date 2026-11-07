class API::V1::ProjectsController < API::V1::BaseController
  def index
    search = Project::Search.new(search_params.merge(user: current_user))

    if search.valid?
      render_json_with_success(
        status: :ok,
        data: {
          projects: Project::Serializer.new(search.projects),
          pagination: { next: search.next_cursor, count: search.count, limit: Project::Search::PER_PAGE }
        }
      )
    else
      render_json_with_model_errors(search)
    end
  end

  def show
    render_json_with_success(status: :ok, data: { project: Project::Serializer.new(project) })
  end

  def create
    creation = Project::Creation.new(project_params.merge(user: current_user))

    if creation.save
      render_json_with_success(
        status: :created,
        message: I18n.t("project.creation.success"),
        data: { project: Project::Serializer.new(creation.project) }
      )
    else
      render_json_with_model_errors(creation)
    end
  end

  def update
    update = Project::Update.new(project_update_params.merge(project:))

    if update.save
      render_json_with_success(
        status: :ok,
        message: I18n.t("project.update.success"),
        data: { project: Project::Serializer.new(update.project) }
      )
    else
      render_json_with_model_errors(update)
    end
  end

  def destroy
    project.destroy!

    render_json_with_success(status: :ok, message: I18n.t("project.deletion.success"))
  end

  private

  def project
    @project ||= current_user.projects.find(params[:id])
  end

  def search_params
    params.permit(:search, :sort, :favorite, :after).to_h
  end

  def project_params
    params.permit(:name, :client_name, :start_date, :end_date, :cover_image).to_h
  end

  def project_update_params
    params.permit(:name, :client_name, :start_date, :end_date, :cover_image, :remove_cover_image).to_h
  end
end
