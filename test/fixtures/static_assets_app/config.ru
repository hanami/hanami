require './config/environment'

if Lotus.environment.serve_static_assets?
  require 'lotus/static'
  use Lotus::Static
end

run StaticAssetsApp::Application.new
