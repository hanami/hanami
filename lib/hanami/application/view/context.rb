# frozen_string_literal: true

require "hanami/view"
require "hanami/view/context"
require_relative "../../errors"
require_relative "../../slice_configurable"
require_relative "slice_configured_context"

module Hanami
  class Application
    class View < Hanami::View
      # View context for views in Hanami applications.
      #
      # @api public
      # @since 2.0.0
      class Context < Hanami::View::Context
        extend Hanami::SliceConfigurable

        # @api private
        def self.configure_for_slice(slice)
          extend SliceConfiguredContext.new(slice)
        end

        # @see SliceConfiguredContext#define_new
        def initialize(**kwargs)
          defaults = {content: {}}

          super(**kwargs, **defaults)
        end

        def inflector
          _options.fetch(:inflector)
        end

        def routes
          _options.fetch(:routes)
        end

        def settings
          _options.fetch(:settings)
        end

        def helpers
          _options.fetch(:helpers)
        end

        def assets
          unless _options[:assets]
            raise Hanami::ComponentLoadError, "hanami-assets gem is required to access assets"
          end

          _options[:assets]
        end

        def content_for(key, value = nil, &block)
          content = _options[:content]
          output = nil

          if block
            content[key] = yield
          elsif value
            content[key] = value
          else
            output = content[key]
          end

          output
        end

        def current_path
          request.fullpath
        end

        def csrf_token
          request.session[Hanami::Action::CSRFProtection::CSRF_TOKEN]
        end

        def request
          _options.fetch(:request)
        end

        def session
          request.session
        end

        def flash
          response.flash
        end

        private

        # TODO: create `Request#flash` so we no longer need the `response`
        def response
          _options.fetch(:response)
        end
      end
    end
  end
end
