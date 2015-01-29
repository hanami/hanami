require 'lotus/router'
require 'lotus/view'
require 'lotus/controller'
require 'lotus/action/glue'

Lotus::Controller.configure do
  prepare do
    include Lotus::Action::Glue
  end
end
