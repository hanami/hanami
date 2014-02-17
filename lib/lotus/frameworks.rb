require 'lotus/router'
require 'lotus/model'
require 'lotus/controller'
require 'lotus/view'
require 'lotus/view/view_loader'

module Lotus
  module Action
    Throwable.class_eval do
      protected
      def status(code, message)
        self.status = code
      end
    end

    Rack.class_eval do
      # FIXME try do inject this behavior in order to implement like this:
      # def response
      #   [ super, self ].flatten
      # end
      def response
        [ @_status || Rack::DEFAULT_RESPONSE_CODE, headers, @_body || Rack::DEFAULT_RESPONSE_BODY.dup, self ]
      end
    end
  end

  class NullAction
    def exposures
      {}
    end
  end

  module View
    module Rendering
      class TemplatesFinder
        protected
        def template_name
          "{#{ @view.template.gsub(template_prefix, template_suffix) },**/#{template_suffix}/#{@view.template.gsub('_view', '')}}"
        end

        private
        def template_prefix
          config.template_prefix
        end

        def template_suffix
          config.template_suffix
        end

        def view_suffix
          config.view_suffix
        end

        def config
          View.config
        end
      end
    end

    class << self
      attr_accessor :config
    end

    def self.render(response)
      action = response[3]
      format = :html # TODO response.format
      view_for(response).render({format: format}, action.exposures)
    end

    protected
    def self.view_for(response)
      Lotus::View::ViewLoader.load!(response, config)
    end
  end
end
