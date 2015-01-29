require 'lotus/utils/class'
require 'lotus/views/default'
require 'lotus/views/null_view'

module Lotus
  # Rendering policy
  #
  # @since 0.1.0
  # @api private
  class RenderingPolicy
    STATUS  = 0
    HEADERS = 1
    BODY    = 2

    LOTUS_ACTION = 'lotus.action'.freeze

    SUCCESSFUL_STATUSES = (200..201).freeze
    RENDERABLE_FORMATS  = [:all, :html].freeze

    def initialize(configuration)
      @controller_pattern = %r{#{ configuration.controller_pattern.gsub(/\%\{(controller|action)\}/) { "(?<#{ $1 }>(.*))" } }}
      @view_pattern       = configuration.view_pattern
      @namespace          = configuration.namespace
      @templates          = configuration.templates
    end

    def render(env, response)
      body = _render(env, response)

      response[BODY] = Array(body) unless body.nil?
      response
    end

    private
    def _render(env, response)
      if action = renderable?(env)
        _render_action(action, response) ||
          _render_status_page(action, response)
      end
    end

    def _render_action(action, response)
      if successful?(response)
        view_for(action, response).render(
          action.exposures
        )
      end
    end

    def _render_status_page(action, response)
      if render_status_page?(action, response)
        Lotus::Views::Default.render(@templates, response[STATUS], response: response, format: :html)
      end
    end

    def renderable?(env)
      ((action = env.delete(LOTUS_ACTION)) && action.renderable? ) and action
    end

    def successful?(response)
      SUCCESSFUL_STATUSES.include?(response[STATUS])
    end

    def render_status_page?(action, response)
      RENDERABLE_FORMATS.include?(action.format)
    end

    def view_for(action, response)
      if response[BODY].empty?
        captures = @controller_pattern.match(action.class.name)
        Utils::Class.load!(@view_pattern % { controller: captures[:controller], action: captures[:action] }, @namespace)
      else
        Views::NullView.new(response[BODY])
      end
    end
  end
end
