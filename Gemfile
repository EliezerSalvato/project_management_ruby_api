source "https://rubygems.org"

ruby "3.4.12"

# Core
gem "rails", "~> 8.1.4"
gem "pg", "~> 1.7"
gem "puma", "~> 8.0"
gem "bootsnap", "~> 1.26", require: false

# API
gem "jsonapi-serializer", "~> 2.2"
gem "rack-cors", "~> 3.0"
gem "rack-attack", "~> 6.8"

# I18n
gem "rails-i18n", "~> 8.1"

# Auth / security
gem "bcrypt", "~> 3.1"

group :development do
  gem "rubocop-rails-omakase", "~> 1.1", require: false
  gem "i18n-tasks", "~> 1.2"
end

group :test do
  gem "simplecov", "~> 1.3", require: false
  gem "rspec-rails", "~> 8.0"
end

group :development, :test do
  gem "dotenv-rails", "~> 3.2"
  gem "factory_bot_rails", "~> 6.5"
  gem "faker", "~> 3.8"
  gem "brakeman", "~> 8.1", require: false
  gem "bundler-audit", "~> 0.9", require: false
  gem "debug", "~> 1.11", platforms: %i[mri windows], require: "debug/prelude"
end
