# frozen_string_literal: true

source "https://rubygems.org"

gemspec

eval_gemfile "Gemfile.devtools"

unless ENV["CI"]
  gem "yard"
  gem "yard-junk"
end

if ENV["RACK_MATRIX_VALUE"]
  gem "rack", ENV["RACK_MATRIX_VALUE"]
end

gem "hanami-utils", "~> 3.0.0"
gem "hanami-db", "~> 3.0.0"
gem "hanami-router", "~> 3.0.0"
gem "hanami-action", "~> 3.0.0"
gem "hanami-cli", "~> 3.0.0"
gem "hanami-view", "~> 3.0.0"
gem "hanami-mailer", "~> 3.0.0"
gem "hanami-assets", "~> 3.0.0"
gem "hanami-webconsole", "~> 3.0.0"

gem "hanami-devtools", github: "hanami/devtools", branch: "main"

# For testing settings with types
gem "dry-types"

# For testing operation integrations
gem "dry-operation", github: "dry-rb/dry-operation", branch: "main"

# For testing the DB layer
gem "sqlite3", platform: :mri
gem "jdbc-sqlite3", platform: :jruby

# For testing SQL logging
gem "rouge"

# For testing i18n support
gem "i18n"

# Work around RDoc/JRuby incompatibiltiy: rdoc 8 depends on rbs 4, whose native C extension can't
# build on JRuby.
#
# Remove this once https://github.com/ruby/rdoc/issues/1746 is resolved.
gem "rdoc", "< 8.0"

group :test do
  gem "capybara"
  gem "dotenv"
  gem "saharspec"
  gem "slim"
end
