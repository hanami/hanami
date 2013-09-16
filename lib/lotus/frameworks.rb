require 'lotus/router'
require 'lotus/controller'
require 'lotus/view'
require 'lotus/view/view_loader'

module Lotus
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
      action = response.action
      format = :html # response.format
      view_for(action).render({format: format}, action.exposures)
    end

    protected
    def self.view_for(action)
      Lotus::View::ViewLoader.new(action, config).load!
    end
  end
end
