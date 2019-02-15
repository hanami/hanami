# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "hanami-utils",      "~> 2.0.alpha", require: false, git: "https://github.com/hanami/utils.git",      branch: "enhancement/file-list-join"
gem "hanami-router",     "~> 2.0.alpha", require: false, git: "https://github.com/hanami/router.git",     branch: "enhancement/router-endpoint-finder"
gem "hanami-controller", "~> 2.0.alpha", require: false, git: "https://github.com/hanami/controller.git", branch: "enhancement/action-name"
gem "hanami-cli",        "~> 1.0.alpha", require: false, git: "https://github.com/hanami/cli.git",        branch: "unstable"

gem "hanami-devtools", require: false, git: "https://github.com/hanami/devtools.git"
