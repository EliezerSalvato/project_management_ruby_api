class API::V1::User::Password::ChangesController < API::V1::BaseController
  def update
    change = User::Password::Change.new(change_params)

    if change.save
      render_json_with_success(status: :ok, message: I18n.t("user.password.change.success"))
    else
      render_json_with_model_errors(change)
    end
  end

  private

  def change_params
    params.permit(:current_password, :password, :password_confirmation).to_h.merge(user: current_user)
  end
end
