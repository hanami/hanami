# frozen_string_literal: true

require "hanami/action"

module Hanami
  # Application integration extensions to Hanami::Action
  # @since 2.0.0
  class Action
    # FIXME: this is a total hack to make the actions respond with an HTML
    # mime-type by default
    #
    # We need to move this into an application-level config and pull it in like
    # we do for Views
    #
    # Ignoring this for now because this will be simpler to do once we have
    # class-level configuration
    #
    # DEFAULT_CONFIGURATION = Hanami::Controller::Configuration.new { |config|
    #   config.default_request_format = :html
    # }

    attr_reader :view_context

    # FIXME: this has to _copy_ the full #initialize from Hanami::Action, which
    # is gross, because we're monkey-patching, not subclassing.
    def initialize(**deps)
      @_deps = deps

      # FIXME: I have to do this in #initialize here instead of .new because
      # we're monkey-patching the existing class, and we need to keep the
      # existing (very long) .new behavior
      view_context = deps[:view_context]

      # TODO: we need to be able to get the view context off the slice, not just
      # the application
      #
      # Can we infer the slice? e.g. based on the module path of the current
      # class?
      if !view_context && Hanami.application.key?("view.context")
        view_context = Hanami.application["view.context"]
      end

      @view_context = view_context
    end

    # Even more annoyingness due to no subclasing
    alias_method :original_build_response, :build_response

    def build_response(**options)
      options = options.merge(view_options: method(:view_options))
      original_build_response(**options)
    end

    private

    def view_options(req, res)
      {context: view_context&.with(view_context_options(req, res))}.compact
    end

    def view_context_options(req, res)
      {
        csrf_token: req.session[Hanami::Action::CSRFProtection::CSRF_TOKEN],
        flash: res.flash
      }
    end
  end
end
