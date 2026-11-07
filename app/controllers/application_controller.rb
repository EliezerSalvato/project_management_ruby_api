class ApplicationController < ActionController::API
  include ActionController::Cookies

  private

  # Wraps process_action instead of using around_action so rescue_from handlers,
  # which run outside the callback chain, also answer in the requested locale.
  def process_action(*)
    I18n.with_locale(requested_locale) { super }
  end

  # In production the frontend runs on another site, so its locale cookie never reaches the API.
  # Clients there send Accept-Language instead; the cookie keeps working when both share a site.
  def requested_locale
    find_available_locale(cookies[:locale]) || locale_from_accept_language || I18n.default_locale
  end

  # Picks the highest-weighted language the app supports, matching "en-US" to "en" and "pt" to "pt-BR".
  def locale_from_accept_language
    accepted_language_tags.each do |tag|
      locale = find_available_locale(tag) || find_available_locale(tag.split("-").first, by_language: true)
      return locale if locale
    end

    nil
  end

  def accepted_language_tags
    request.headers["Accept-Language"].to_s.split(",").filter_map.with_index do |entry, index|
      tag, quality = entry.split(";q=").map(&:strip)
      [ tag, -(quality || 1).to_f, index ] if tag.present?
    end.sort_by { |_, weight, index| [ weight, index ] }.map(&:first)
  end

  def find_available_locale(tag, by_language: false)
    return if tag.blank?

    I18n.available_locales.map(&:to_s).find do |locale|
      (by_language ? locale.split("-").first : locale).casecmp?(tag)
    end
  end
end
