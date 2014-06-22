require 'lotus/utils/class'
require 'lotus/views/default'
require 'lotus/views/null_view'

module Lotus
  class RenderingPolicy
    STATUS  = 0
    HEADERS = 1
    BODY    = 2

    RACK_RESPONSE_SIZE = 3

    SUCCESSFUL_STATUSES   = (200..201).freeze
    STATUSES_WITHOUT_BODY = Set.new((100..199).to_a << 204 << 205 << 301 << 302 << 304).freeze
    RENDERABLE_FORMATS    = [:all, :html].freeze
    CONTENT_TYPE          = 'Content-Type'.freeze

    def initialize(configuration)
      @controller_pattern = %r{#{ configuration.controller_pattern.gsub(/\%\{(controller|action)\}/) { "(?<#{ $1 }>(.*))" } }}
      @view_pattern       = configuration.view_pattern
      @namespace          = configuration.namespace
    end

    def render!(response)
      if renderable?(response)
        action = response.pop

        body = if successful?(response)
          view_for(response, action).render(
            action.to_rendering
          )
        else
          if render_status_page?(response, action)
            Lotus::Views::Default.render(response: response, format: :html)
          end
        end

        response[BODY] = Array(body) if body
      end
    end

    private
    def renderable?(response)
      response.size > RACK_RESPONSE_SIZE
    end

    def successful?(response)
      SUCCESSFUL_STATUSES.include?(response[STATUS])
    end

    def render_status_page?(response, action)
      RENDERABLE_FORMATS.include?(action.format) &&
        !STATUSES_WITHOUT_BODY.include?(response[STATUS])
    end

    def view_for(response, action)
      if response[BODY].empty?
        captures = @controller_pattern.match(action.class.name)
        Utils::Class.load!(@view_pattern % { controller: captures[:controller], action: captures[:action] }, @namespace)
      else
        Views::NullView.new(response[BODY])
      end
    end
  end
end
