class API::V1::User::Session::RevokesController < API::V1::BaseController
  def destroy
    current_user.sessions.active.revoke_all

    render_json_with_success(status: :ok, message: I18n.t("user.session.revoke.success"))
  end
end
