require 'hanami/utils/class'
require 'hanami/views/default'
require 'hanami/views/null_view'

module Hanami
  # Renderer
  #
  # @since x.x.x
  # @api private
  class Renderer
    # @api private
    STATUS  = 0
    # @api private
    HEADERS = 1
    # @api private
    BODY    = 2

    # @api private
    HANAMI_ACTION = 'hanami.action'.freeze
    # @api private
    RACK_EXCEPTION = 'rack.exception'.freeze

    # @api private
    SUCCESSFUL_STATUSES = (200..201).freeze
    # @api private
    RENDERABLE_FORMATS = [:all, :html].freeze

    def initialize
      @root = Hanami.root
    end

    # @api private
    def render(env, response)
      body = _render(env, response)

      response[BODY] = Array(body) unless body.nil? || body.respond_to?(:each)
      response
    end

    private
    # @api private
    def _render(env, response)
      if action = renderable?(env)
        _render_action(action, env, response) ||
          _render_status_page(action, response)
      end
    end

    # @api private
    def _render_action(action, env, response)
      begin
        view_for(action, response).render(
          action.exposures
        )
      rescue => e
        env[RACK_EXCEPTION] = e
        raise e
      end
    end

    # @api private
    def _render_status_page(action, response)
      if render_status_page?(action, response)
        Hanami::Views::Default.render(@root, response[STATUS], response: response, format: :html)
      end
    end

    # @api private
    def renderable?(env)
      ((action = env.delete(HANAMI_ACTION)) && action.renderable?) and action
    end

    # @api private
    def render_status_page?(action, response)
      RENDERABLE_FORMATS.include?(action.format) && !SUCCESSFUL_STATUSES.include?(response[STATUS])
    end

    # @api private
    def view_for(action, response)
      # FIXME: set in the container registry the action/view associations
      view = if response[BODY].respond_to?(:empty?) && response[BODY].empty?
        tokens = action.class.name.split("::")
        tokens[1] = "Views"

        Utils::Class.load(tokens.join("::"))
      end

      view || Views::NullView.new
    end
  end
end
