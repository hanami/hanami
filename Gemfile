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

gem "dry-auto_inject", github: "dry-rb/dry-auto_inject"
gem "dry-configurable", github: "dry-rb/dry-configurable"
gem "dry-core", github: "dry-rb/dry-core"
gem "dry-events", github: "dry-rb/dry-events"
gem "dry-inflector", github: "dry-rb/dry-inflector"
gem "dry-logic", github: "dry-rb/dry-logic"
gem "dry-monitor", github: "dry-rb/dry-monitor"
gem "dry-system", github: "dry-rb/dry-system"
gem "dry-types", github: "dry-rb/dry-types"

group :test do
  gem "dotenv"
  gem "saharspec"
  gem "slim"
end
