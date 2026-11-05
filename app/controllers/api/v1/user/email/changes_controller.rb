class API::V1::User::Email::ChangesController < API::V1::BaseController
  def update
    change = User::Email::Change.new(change_params)

    if change.save
      render_json_with_success(status: :ok, message: I18n.t("user.email.change.success"))
    else
      render_json_with_model_errors(change)
    end
  end

  private

  def change_params
    params.permit(:current_password, :new_email).to_h.merge(user: current_user)
  end
end
