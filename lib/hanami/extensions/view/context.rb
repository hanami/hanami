# frozen_string_literal: true

require "hanami/view"
require "hanami/view/context"
require_relative "../../errors"

module Hanami
  module Extensions
    module View
      # View context for views in Hanami apps.
      #
      # This is NOT RELEASED as of 2.0.0.
      #
      # @api private
      module Context
        def self.included(context_class)
          super

          context_class.extend(Hanami::SliceConfigurable)
          context_class.extend(ClassMethods)
          context_class.prepend(InstanceMethods)
        end

        module ClassMethods
          def configure_for_slice(slice)
            extend SliceConfiguredContext.new(slice)
          end
        end

        module InstanceMethods
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
end

Hanami::View::Context.include(Hanami::Extensions::View::Context)
