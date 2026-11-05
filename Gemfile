source "https://rubygems.org"

ruby "3.4.5"

# Core
gem "rails", "~> 8.1.4"
gem "pg", "~> 1.7"
gem "puma", "~> 8.0"
gem "bootsnap", "~> 1.26", require: false

# API
gem "jsonapi-serializer", "~> 2.2"
gem "pagy", "~> 43.8"
gem "ransack", "~> 6.0"
gem "rack-cors", "~> 3.0"
gem "rack-attack", "~> 6.8"

group :development do
  gem "rubocop-rails-omakase", "~> 1.1", require: false
end

group :test do
  gem "simplecov", "~> 1.3", require: false
end

group :development, :test do
  gem "brakeman", "~> 8.1", require: false
  gem "bundler-audit", "~> 0.9", require: false
  gem "debug", "~> 1.11", platforms: %i[mri windows], require: "debug/prelude"
end
