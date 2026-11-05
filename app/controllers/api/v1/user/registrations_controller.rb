class API::V1::User::RegistrationsController < API::V1::BaseController
  skip_before_action :authenticate_user!

  def create
    registration = User::Registration.new(registration_params)

    if registration.save
      render_json_with_success(
        status: :created,
        message: I18n.t("user.registration.success"),
        data: { user: User::Serializer.new(registration.user) }
      )
    else
      render_json_with_model_errors(registration)
    end
  end

  private

  def registration_params
    params.permit(:first_name, :last_name, :email, :password, :password_confirmation).to_h
  end
end
