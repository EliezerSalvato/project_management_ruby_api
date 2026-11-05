class API::V1::User::Email::ConfirmationsController < API::V1::BaseController
  skip_before_action :authenticate_user!

  def create
    confirmation = User::Email::Confirmation.new(confirmation_params)

    if confirmation.save
      render_json_with_success(status: :ok, message: I18n.t("user.email.confirmation.success"))
    else
      render_json_with_model_errors(confirmation)
    end
  end

  private

  def confirmation_params
    params.permit(:token).to_h
  end
end
