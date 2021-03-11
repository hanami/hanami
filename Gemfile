# frozen_string_literal: true

source "https://rubygems.org"

gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "hanami-utils", "~> 2.0.alpha", require: false, git: "https://github.com/hanami/utils.git", branch: "unstable"
gem "hanami-router", "~> 2.0.alpha", require: false, git: "https://github.com/hanami/router.git", branch: "unstable"
gem "hanami-controller", "~> 2.0.alpha", require: false, git: "https://github.com/hanami/controller.git", branch: "unstable"
gem "dry-cli", "~> 0.6", require: false, git: "https://github.com/dry-rb/dry-cli.git", branch: "feature/file-utils-class"
gem "hanami-cli", "~> 2.0.alpha", require: false, git: "https://github.com/hanami/cli.git", branch: "main"
gem "hanami-view", "~> 2.0.alpha", git: "https://github.com/hanami/view.git", branch: "master"

gem "hanami-devtools", require: false, git: "https://github.com/hanami/devtools.git", branch: "unstable"

gem "dry-configurable", git: "https://github.com/dry-rb/dry-configurable.git", branch: "master"

group :test do
  gem "dotenv"
  gem "dry-types"
  gem "slim"
end
