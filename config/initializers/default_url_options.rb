# Absolute URLs built outside a request (e.g. cover image URLs in serializers) use the mailer host.
Rails.application.routes.default_url_options = Rails.application.config.action_mailer.default_url_options || {}
