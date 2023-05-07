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
        class << self
          # Returns a context class for the given slice. If a context class is not defined, defines
          # a class named `Views::Context` within the slice's namespace.
          #
          # @api private
          def context_class(slice)
            views_namespace = views_namespace(slice)

            if views_namespace.const_defined?(:Context)
              return views_namespace.const_get(:Context)
            end

            views_namespace.const_set(:Context, Class.new(context_superclass(slice)).tap { |klass|
              klass.configure_for_slice(slice)
            })
          end

          private

          def context_superclass(slice)
            return Hanami::View::Context if Hanami.app.equal?(slice)

            begin
              slice.inflector.constantize(
                slice.inflector.camelize("#{slice.app.slice_name.name}/views/context")
              )
            rescue NameError => e
              raise e unless %i[Views Context].include?(e.name)

              Hanami::View::Context
            end
          end

          # TODO: this could be moved into the top-level Extensions::View
          def views_namespace(slice)
            if slice.namespace.const_defined?(:Views)
              slice.namespace.const_get(:Views)
            else
              slice.namespace.const_set(:Views, Module.new)
            end
          end
        end

        module ClassExtension
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

            # @see SliceConfiguredContext#define_new
            def initialize( # rubocop:disable Metrics/ParameterLists
              inflector: nil,
              settings: nil,
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
              # The standard implementation of initialize_copy will make shallow copies of all
              # instance variables from the source. This is fine for most of our ivars.
              super

              # Dup any objects that will be mutated over a given rendering to ensure no leakage of
              # state across distinct view renderings.
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
                raise Hanami::ComponentLoadError, "the hanami-assets gem is required to access assets"
              end

              @assets
            end

            def request
              unless @request
                raise Hanami::ComponentLoadError, "only views rendered from Hanami::Action instances have a request"
              end

              @request
            end

            def routes
              unless @routes
                raise Hanami::ComponentLoadError, "the hanami-router gem is required to access routes"
              end

              @routes
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
end

Hanami::View::Context.include(Hanami::Extensions::View::Context::ClassExtension)
