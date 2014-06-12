module Lotus
  class Routes
    def initialize(routes)
      @routes = routes
    end

    # @raise Lotus::Routing::InvalidRouteException
    def path(name)
      @routes.path(name)
    end

    # @raise Lotus::Routing::InvalidRouteException
    def url(name)
      @routes.url(name)
    end
  end
end
