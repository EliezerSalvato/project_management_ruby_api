class API::V1::User::Password::ResetsController < API::V1::BaseController
  skip_before_action :authenticate_user!

  def create
    instructions = User::Password::Reset::SendInstructions.new(reset_instructions_params)

    if instructions.save
      render_json_with_success(status: :ok, message: I18n.t("user.password.reset_instructions.success"))
    else
      render_json_with_model_errors(instructions)
    end
  end

  def update
    reset = User::Password::Reset.new(reset_params)

    if reset.save
      render_json_with_success(status: :ok, message: I18n.t("user.password.reset.success"))
    else
      render_json_with_model_errors(reset)
    end
  end

  private

  def reset_instructions_params
    params.permit(:email).to_h
  end

  def reset_params
    params.permit(:token, :password, :password_confirmation).to_h
  end
end
