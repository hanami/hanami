# frozen_string_literal: true

source "https://rubygems.org"

gemspec

eval_gemfile "Gemfile.devtools"

unless ENV["CI"]
  gem "yard"
  gem "yard-junk"
end

if ENV["RACK_MATRIX_VALUE"]
  gem "rack", ENV["RACK_MATRIX_VALUE"]
end

gem "hanami-utils", github: "hanami/hanami-utils", branch: "main"
gem "hanami-db", github: "hanami/hanami-db", branch: "main"
gem "hanami-router", github: "hanami/hanami-router", branch: "main"
gem "hanami-controller", github: "hanami/hanami-controller", branch: "main"
gem "hanami-cli", github: "hanami/hanami-cli", branch: "main"
gem "hanami-view", github: "hanami/hanami-view", branch: "main"
gem "hanami-assets", github: "hanami/hanami-assets", branch: "main"
gem "hanami-webconsole", github: "hanami/hanami-webconsole", branch: "main"

gem "hanami-devtools", github: "hanami/devtools", branch: "main"

# This is needed for settings specs to pass
gem "dry-types"

# For testing operation integrations
gem "dry-operation", github: "dry-rb/dry-operation", branch: "main"

# For testing the DB layer
gem "sqlite3", platform: :mri
gem "jdbc-sqlite3", platform: :jruby

group :test do
  gem "capybara"
  gem "dotenv"
  gem "saharspec"
  gem "slim"
end

group :tools do
  gem "rubocop"
end
