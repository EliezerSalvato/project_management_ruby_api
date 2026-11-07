class API::V1::User::AuthenticationsController < API::V1::BaseController
  skip_before_action :authenticate_user!

  def create
    authentication = User::Authentication.new(authentication_params)

    if authentication.save
      set_refresh_token_as_cookie(refresh_token: authentication.refresh_token, remember_me: authentication.remember_me)

      render_json_with_success(
        status: :ok,
        data: { token: authentication.token, user: User::Serializer.new(authentication.user) }
      )
    else
      render_json_with_model_errors(authentication)
    end
  end

  private

  def authentication_params
    params.permit(:email, :password, :remember_me).to_h.merge(request_metadata)
  end
end
