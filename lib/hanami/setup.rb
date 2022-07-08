# frozen_string_literal: true

require "bundler/setup"
require "hanami"

begin
  app_require_path = File.join(Dir.pwd, "config/app")
  require app_require_path
rescue LoadError => e
  raise e unless e.path == app_require_path
end
