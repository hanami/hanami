# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", platforms: :mri
  gem "yard"
  gem "yard-junk"
end

gem "hanami-utils",      github: "hanami/utils",      branch: "main"
gem "hanami-router",     github: "hanami/router",     branch: "main"
gem "hanami-controller", github: "hanami/controller", branch: "main"
gem "hanami-cli",        github: "hanami/cli",        branch: "main"
gem "hanami-view",       github: "hanami/view",       branch: "main"
gem "hanami-assets",     github: "hanami/assets",     branch: "main"
gem "hanami-webconsole", github: "hanami/webconsole", branch: "main"

gem "hanami-devtools", github: "hanami/devtools", branch: "main"

gem "dry-system", github: "dry-rb/dry-system", branch: "main"

# This is needed for settings specs to pass
gem "dry-types"

group :test do
  gem "capybara"
  gem "dotenv"
  gem "saharspec"
  gem "slim"
end
