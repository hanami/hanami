require 'lotus/utils/class'

module Lotus
  class RenderingPolicy
    def render!(response)
      if response.size > 3
        # FIXME don't assume that "Controllers" will be always part of the class name
        action = response.pop
        view   = Utils::Class.load!(action.class.name.gsub('Controllers', 'Views'))

        # FIXME consider only "renderable" statuses
        # FIXME handle non-successful statuses with Lotus views such as Lotus::Views::ServerErrorView
        response[2] = Array(view.render(action.exposures.merge(format: :html)))
      end
    end
  end
end
