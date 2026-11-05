class API::V1::User::ProfilesController < API::V1::BaseController
  def update
    profile = User::Profile::Update.new(profile_params)

    if profile.save
      render_json_with_success(status: :ok, message: I18n.t("user.profile.update.success"))
    else
      render_json_with_model_errors(profile)
    end
  end

  private

  def profile_params
    params.permit(:first_name, :last_name).to_h.merge(user: current_user)
  end
end
