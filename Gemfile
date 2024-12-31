# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", platforms: :mri
  gem "yard"
  gem "yard-junk"
end

gem "hanami-utils", github: "hanami/utils", branch: "main"
gem "hanami-db", github: "hanami/db", branch: "add-ruby-3-4-support"
gem "hanami-router", github: "hanami/router", branch: "add-ruby-3-4-support"
gem "hanami-controller", github: "hanami/controller", branch: "add-ruby-3-4-support"
gem "hanami-cli", github: "hanami/cli", branch: "add-ruby-3-4-support"
gem "hanami-view", github: "hanami/view", branch: "add-ruby-3-4-support"
gem "hanami-assets", github: "hanami/assets", branch: "add-ruby-3-4-support"
gem "hanami-webconsole", github: "hanami/webconsole", branch: "add-ruby-3-4-support"

gem "hanami-devtools", github: "hanami/devtools", branch: "add-ruby-3-4-support"

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
