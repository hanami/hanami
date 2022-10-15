# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", platforms: :mri
  gem "yard"
end

gem "hanami-utils",      github: "hanami/utils",      branch: "main"
gem "hanami-router",     github: "hanami/router",     branch: "main"
gem "hanami-controller", github: "hanami/controller", branch: "main"
gem "hanami-cli",        github: "hanami/cli",        branch: "main"
gem "hanami-view",       github: "hanami/view",       branch: "main"

gem "hanami-devtools", github: "hanami/devtools", branch: "main"

gem "dry-types", "~> 1.6.1"

group :test do
  gem "dotenv"
  gem "saharspec"
  gem "slim"
end
