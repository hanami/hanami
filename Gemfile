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

gem "hanami-utils", github: "hanami/utils", branch: "main"
gem "hanami-db", github: "hanami/db", branch: "main"
gem "hanami-router", github: "hanami/router", branch: "improve-name-flexibility"
gem "hanami-controller", github: "hanami/controller", branch: "main"
gem "hanami-cli", github: "hanami/cli", branch: "main"
gem "hanami-view", github: "hanami/view", branch: "main"
gem "hanami-assets", github: "hanami/assets", branch: "main"
gem "hanami-webconsole", github: "hanami/webconsole", branch: "main"

gem "hanami-devtools", github: "hanami/devtools", branch: "main"

# This is needed for settings specs to pass
gem "dry-types"

# For testing operation integrations
gem "dry-operation", github: "dry-rb/dry-operation", branch: "main"

# For testing the DB layer
gem "sqlite3"

group :test do
  gem "capybara"
  gem "dotenv"
  gem "saharspec"
  gem "slim"
end
