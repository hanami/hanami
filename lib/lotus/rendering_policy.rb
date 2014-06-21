require 'lotus/utils/class'
require 'lotus/views/default'

module Lotus
  class RenderingPolicy
    def initialize(configuration)
      # FIXME check if {|capture| } can avoid the usage of $1
      @controller_pattern = %r{#{ configuration.controller_pattern.gsub(/\%\{(controller|action)\}/) { "(?<#{ $1 }>(.*))" } }}
      @view_pattern       = configuration.view_pattern
      @namespace          = configuration.namespace
    end

    def render!(response)
      if response.size > 3
        action = response.pop

        # FIXME consider non 200 statuses
        if response[0] == 200
          view = view_for(action)

          # FIXME consider only "renderable" statuses
          response[2] = Array(view.render(action.exposures.merge(format: :html)))
        else
          # FIXME consider non :html statuses
          response[2] = Lotus::Views::Default.render(response: response, format: :html)
        end
      end
    end

    private
    def view_for(action)
      captures = @controller_pattern.match(action.class.name)
      Utils::Class.load!(@view_pattern % { controller: captures[:controller], action: captures[:action] }, @namespace)
    end
  end
end
