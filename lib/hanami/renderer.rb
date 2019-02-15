# frozen_string_literal: true

module Hanami
  # Hanami response renderer
  #
  # @since 2.0.0
  class Renderer
    def initialize(router)
      @router = router
      freeze
    end

    def call(env)
      render(
        @router.call(env)
      )
    end

    private

    def render(response)
      return response unless response.renderable?

      response.body = view_for(response.action).call(response.exposures)
      response
    end

    def view_for(action)
      Container["apps.#{action.sub(/actions/, 'views')}"]
    end
  end
end
