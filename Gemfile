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
gem "hanami-cli", "~> 1.0.alpha", require: false, git: "https://github.com/hanami/cli.git", branch: "unstable"
gem "hanami-view", "~> 2.0.alpha", git: "https://github.com/hanami/view.git", branch: "master"

gem "hanami-devtools", require: false, git: "https://github.com/hanami/devtools.git", branch: "unstable"

gem "dry-configurable", git: "https://github.com/dry-rb/dry-configurable.git", branch: "master"

group :test do
  gem "dotenv"
  gem "dry-types"
  gem "slim"
end
