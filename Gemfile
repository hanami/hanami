# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", platforms: :mri
  gem "yard"
end

gem "hanami-cli", "~> 2.0.alpha", github: "hanami/cli", branch: "main"
gem "hanami-controller", "~> 2.0.alpha", github: "hanami/controller", branch: "main"
gem "hanami-router", "~> 2.0.alpha", github: "hanami/router", branch: "main"
gem "hanami-utils", "~> 2.0.alpha", github: "hanami/utils", branch: "main"
gem "hanami-view", "~> 2.0.alpha", github: "hanami/view", branch: "main"

gem "hanami-devtools", github: "hanami/devtools", branch: "main"

group :test do
  gem "dotenv"
  gem "saharspec"
  gem "slim"
end
