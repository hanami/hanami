# frozen_string_literal: true

require "hanami/action"

module Hanami
  # Application integration extensions to Hanami::View
  # @since 2.0.0
  class Action
    attr_reader :view_context

    # FIXME: this is a total hack to make the actions respond with an HTML
    # mime-type by default
    #
    # We need to move this into an application-level config and pull it in like
    # we do for Views
    DEFAULT_CONFIGURATION = Hanami::Controller::Configuration.new { |config|
      config.default_request_format = :html
    }

    def self.new(configuration: DEFAULT_CONFIGURATION, view_context: nil, **args)
      if !view_context && Hanami.application.key?("view.context")
        view_context = Hanami.application["view.context"]
      end

      super(configuration: configuration, **args)
    end

    # This has to _copy_ full #initialize from Hanami::Action, which is gross
    def initialize(**deps)
      @_deps = deps
      @view_context = deps[:view_context]
    end

    private

    def render(req, res, view = renderable_view, **args)
      res.body = view.call(context: view_context.with(view_context_options(req, res)), **args)
      res
    end

    # Hook for subclasses to explicitly provide a view for implicit rendering
    def renderable_view
      view
    end

    def view_context_options(req, res)
      {
        csrf_token: req.session[Hanami::Action::CSRFProtection::CSRF_TOKEN],
        flash: res.flash
      }
    end
  end
end
