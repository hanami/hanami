# frozen_string_literal: true

require "bundler/setup"
require "hanami"

begin
  application_require_path = File.join(Dir.pwd, "config/application")
  require application_require_path
rescue LoadError => e
  raise e unless e.path == application_require_path
end
