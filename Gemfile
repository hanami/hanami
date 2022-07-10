# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", platforms: :mri
  gem "yard"
end

gem "hanami-utils", "~> 2.0.alpha", github: "hanami/utils", branch: "main"
gem "hanami-router", "~> 2.0.alpha", github: "hanami/router", branch: "main"
gem "hanami-controller", "~> 2.0.alpha", github: "hanami/controller", branch: "main"
gem "hanami-cli", "~> 2.0.alpha", github: "hanami/cli", branch: "main"
gem "hanami-view", "~> 2.0.alpha", github: "hanami/view", branch: "main"

gem "hanami-devtools", github: "hanami/devtools", branch: "main"

gem "dry-files", github: "dry-rb/dry-files", branch: "main"
gem "dry-monitor", github: "dry-rb/dry-monitor", branch: "main"
gem "dry-system", github: "dry-rb/dry-system", branch: "main"
gem "dry-container", github: "dry-rb/dry-container", branch: "main"

group :test do
  gem "dotenv"
  gem "saharspec"
  gem "slim"
end
