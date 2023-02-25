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
          attr_reader :inflector

          attr_reader :settings

          attr_reader :routes

          attr_reader :request

          # @see SliceConfiguredContext#define_new
          def initialize( # rubocop:disable Metrics/ParameterLists
            inflector:,
            settings:,
            routes: nil,
            assets: nil,
            request: nil,
            **args
          )
            @inflector = inflector
            @settings = settings
            @routes = routes
            @assets = assets
            @request = request

            @content_for = {}

            super(**args)
          end

          def initialize_copy(source)
            super

            # Dup objects that may be mutated over a given rendering
            @content_for = source.instance_variable_get(:@content_for).dup
          end

          def with(**args)
            self.class.new(
              inflector: @inflector,
              settings: @settings,
              assets: @assets,
              routes: @routes,
              request: @request,
              **args
            )
          end

          def assets
            unless @assets
              raise Hanami::ComponentLoadError, "hanami-assets gem is required to access assets"
            end

            @assets
          end

          def content_for(key, value = nil)
            if block_given?
              @content_for[key] = yield
            elsif value
              @content_for[key] = value
            else
              @content_for[key]
            end
          end

          def current_path
            request.fullpath
          end

          def csrf_token
            request.session[Hanami::Action::CSRFProtection::CSRF_TOKEN]
          end

          def session
            request.session
          end

          def flash
            request.flash
          end
        end
      end
    end
  end
end

Hanami::View::Context.include(Hanami::Extensions::View::Context)
