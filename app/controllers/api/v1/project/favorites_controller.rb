class API::V1::Project::FavoritesController < API::V1::BaseController
  def create
    project.update!(favorite: true)

    render_json_with_success(status: :ok, data: { project: Project::Serializer.new(project) })
  end

  def destroy
    project.update!(favorite: false)

    render_json_with_success(status: :ok, data: { project: Project::Serializer.new(project) })
  end

  private

  def project
    @project ||= current_user.projects.find(params[:project_id])
  end
end
