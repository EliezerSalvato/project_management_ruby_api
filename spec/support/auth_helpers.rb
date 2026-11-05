module AuthHelpers
  def bearer_token_for(user, expires_in: User::Token::SESSION_TOKEN_EXPIRES_IN)
    user.signed_id(purpose: :session_token, expires_in:)
  end

  def auth_headers_for(user, expires_in: User::Token::SESSION_TOKEN_EXPIRES_IN)
    { "Authorization" => "Bearer #{bearer_token_for(user, expires_in:)}" }
  end

  def set_refresh_token_cookie(refresh_token)
    jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
    jar.encrypted[:refresh_token] = refresh_token
    cookies[:refresh_token] = jar[:refresh_token]
  end

  def refresh_token_set_cookie
    Array(response.headers["Set-Cookie"]).find { |cookie| cookie.include?("refresh_token=") }
  end

  # A refresh token cookie without `expires` lives only for the current browser session.
  def persistent_refresh_token_cookie?
    refresh_token_set_cookie.match?(/expires=/i)
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
