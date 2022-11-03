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

gem "hanami-devtools", github: "hanami/devtools", branch: "main"

gem "dry-auto_inject", github: "dry-rb/dry-auto_inject", branch: "main"
gem "dry-configurable", github: "dry-rb/dry-configurable", branch: "main"
gem "dry-cli", github: "dry-rb/dry-cli", branch: "main"
gem "dry-core", github: "dry-rb/dry-core", branch: "main"
gem "dry-events", github: "dry-rb/dry-events", branch: "main"
gem "dry-files", github: "dry-rb/dry-files", branch: "main"
gem "dry-inflector", github: "dry-rb/dry-inflector", branch: "main"
gem "dry-logic", github: "dry-rb/dry-logic", branch: "main"
gem "dry-monitor", github: "dry-rb/dry-monitor", branch: "main"
gem "dry-system", github: "dry-rb/dry-system", branch: "main"
gem "dry-types", github: "dry-rb/dry-types", branch: "main"

group :test do
  gem "dotenv"
  gem "saharspec"
  gem "slim"
end
