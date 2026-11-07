class API::V1::User::Session::RefreshesController < API::V1::BaseController
  skip_before_action :authenticate_user!

  def update
    refresh = User::Session::Refresh.new(refresh_params)

    if refresh.save
      set_refresh_token_as_cookie(refresh_token: refresh.refresh_token, remember_me: refresh.remember_me)

      render_json_with_success(
        status: :ok,
        data: { token: refresh.token, user: User::Serializer.new(refresh.user) }
      )
    else
      render_json_with_model_errors(refresh)
    end
  end

  private

  def refresh_params
    params.permit(:remember_me).to_h.merge(refresh_token: cookies.encrypted["refresh_token"])
  end
end
