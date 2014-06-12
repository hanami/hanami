require 'lotus/utils/class'
require 'lotus/views/default'

module Lotus
  class RenderingPolicy
    def render!(response)
      if response.size > 3
        # FIXME don't assume that "Controllers" will be always part of the class name
        action = response.pop

        # FIXME consider non 200 statuses
        if response[0] == 200
          view   = Utils::Class.load!(action.class.name.gsub('Controllers', 'Views'))

          # FIXME consider only "renderable" statuses
          # FIXME handle non-successful statuses with Lotus views such as Lotus::Views::ServerErrorView
          response[2] = Array(view.render(action.exposures.merge(format: :html)))
        else
          # FIXME consider non :html statuses
          response[2] = Lotus::Views::Default.render(response: response, format: :html)
        end
      end
    end
  end
end
