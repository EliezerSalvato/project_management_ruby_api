class API::V1::User::AccountsController < API::V1::BaseController
  def destroy
    deletion = User::Account::Deletion.new(deletion_params)

    if deletion.save
      render_json_with_success(status: :ok, message: I18n.t("user.account.deletion.success"))
    else
      render_json_with_model_errors(deletion)
    end
  end

  private

  def deletion_params
    params.permit(:password).to_h.merge(user: current_user)
  end
end
