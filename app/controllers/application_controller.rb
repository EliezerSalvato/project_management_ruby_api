class ApplicationController < ActionController::API
  include ActionController::Cookies

  private

  # Wraps process_action instead of using around_action so rescue_from handlers,
  # which run outside the callback chain, also answer in the requested locale.
  def process_action(*)
    I18n.with_locale(locale_from_cookie) { super }
  end

  def locale_from_cookie
    locale = cookies[:locale].presence

    I18n.available_locales.map(&:to_s).include?(locale) ? locale : I18n.default_locale
  end
end
