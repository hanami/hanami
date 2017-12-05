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
      response.body = _render(env, response)
      response
    end

    private

    # @api private
    def _render(env, response)
      return unless response.renderable?

      _render_action(env, response) ||
        _render_status_page(response)
    end

    # @api private
    def _render_action(env, response)
      begin
        view_for(response).render(
          response.exposures
        )
      rescue => e
        env[RACK_EXCEPTION] = e
        raise e
      end
    end

    # @api private
    def _render_status_page(response)
      return unless render_status_page?(response)

      Hanami::Views::Default.render(@root, response.status, response: response, format: :html)
    end

    # @api private
    def render_status_page?(response)
      RENDERABLE_FORMATS.include?(response.format) && !SUCCESSFUL_STATUSES.include?(response.status)
    end

    # @api private
    def view_for(response)
      # FIXME: set in the container registry the action/view associations
      view = if response.body.respond_to?(:empty?) && response.body.empty?
        tokens = response.action.split("::")
        tokens[1] = "Views"

        Utils::Class.load(tokens.join("::"))
      end

      view || Views::NullView.new
    end
  end
end
