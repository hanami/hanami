# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", platforms: :mri
  gem "yard"
  gem "yard-junk"
end

if ENV["RACK_VERSION_CONSTRAINT"]
  gem "rack", ENV["RACK_VERSION_CONSTRAINT"]
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
gem "dry-logger", github: "dry-rb/dry-logger", branch: "main"

# For testing the DB layer
gem "sqlite3"

group :test do
  gem "capybara"
  gem "dotenv"
  gem "saharspec"
  gem "slim"
end
