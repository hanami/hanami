# frozen_string_literal: true

require_relative "../../errors"

module Hanami
  module Extensions
    module View
      # View context for views in Hanami apps.
      #
      # @api public
      # @since 2.1.0
      module Context
        class << self
          # Returns a context class for the given slice. If a context class is not defined, defines
          # a class named `Views::Context` within the slice's namespace.
          #
          # @api private
          # @since 2.1.0
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

          # @api private
          # @since 2.1.0
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

          # @api private
          # @since 2.1.0
          def views_namespace(slice)
            # TODO: this could be moved into the top-level Extensions::View
            if slice.namespace.const_defined?(:Views)
              slice.namespace.const_get(:Views)
            else
              slice.namespace.const_set(:Views, Module.new)
            end
          end
        end

        # @api private
        # @since 2.1.0
        module ClassExtension
          def self.included(context_class)
            super

            context_class.extend(Hanami::SliceConfigurable)
            context_class.extend(ClassMethods)
            context_class.prepend(InstanceMethods)
          end

          # @api private
          # @since 2.1.0
          module ClassMethods
            # @api private
            # @since 2.1.0
            def configure_for_slice(slice)
              extend SliceConfiguredContext.new(slice)
            end
          end

          # @api public
          # @since 2.1.0
          module InstanceMethods
            # Returns the app's inflector.
            #
            # @return [Dry::Inflector] the inflector
            #
            # @api public
            # @since 2.1.0
            attr_reader :inflector

            # Returns the app's settings.
            #
            # @return [Hanami::Settings] the settings
            #
            # @api public
            # @since 2.1.0
            attr_reader :settings

            # @see SliceConfiguredContext#define_new
            #
            # @api private
            # @since 2.1.0
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

            # @api private
            # @since 2.1.0
            def initialize_copy(source)
              # The standard implementation of initialize_copy will make shallow copies of all
              # instance variables from the source. This is fine for most of our ivars.
              super

              # Dup any objects that will be mutated over a given rendering to ensure no leakage of
              # state across distinct view renderings.
              @content_for = source.instance_variable_get(:@content_for).dup
            end

            # Returns the app's assets.
            #
            # @return [Hanami::Assets] the assets
            #
            # @raise [Hanami::ComponentLoadError] if the hanami-assets gem is not bundled
            #
            # @api public
            # @since 2.1.0
            def assets
              unless @assets
                msg =
                  if Hanami.bundled?("hanami-assets")
                    "Have you put files into your assets directory?"
                  else
                    "The hanami-assets gem is required to access assets."
                  end

                raise Hanami::ComponentLoadError, "Assets not available. #{msg}"
              end

              @assets
            end

            # Returns the current request, if  the view is rendered from within an action.
            #
            # @return [Hanami::Action::Request] the request
            #
            # @raise [Hanami::ComponentLoadError] if the view is not rendered from within a request
            #
            # @api public
            # @since 2.1.0
            def request
              unless @request
                raise Hanami::ComponentLoadError, "Request not available. Only views rendered from Hanami::Action instances have a request."
              end

              @request
            end

            # Returns the app's routes helper.
            #
            # @return [Hanami::Slice::RoutesHelper] the routes helper
            #
            # @raise [Hanami::ComponentLoadError] if the hanami-router gem is not bundled or routes
            #   are not defined
            #
            # @api public
            # @since 2.1.0
            def routes
              unless @routes
                raise Hanami::ComponentLoadError, "the hanami-router gem is required to access routes"
              end

              @routes
            end

            # @overload content_for(key, value = nil, &block)
            #   Stores a string or block of template markup for later use.
            #
            #   @param key [Symbol] the content key, for later retrieval
            #   @param value [String, nil] the content, if no block is given
            #
            #   @return [String] the content
            #
            #   @example
            #     content_for(:page_title, "Hello world")
            #
            #   @example In a template
            #     <%= content_for :page_title do %>
            #       <h1>Hello world</h1>
            #     <% end %>
            #
            # @overload content_for(key)
            #   Returns the previously stored content for the given key.
            #
            #   @param key [Symbol] the content key
            #
            #   @return [String, nil] the content, or nil if no content previously stored with the
            #     key
            #
            # @api public
            # @since 2.1.0
            def content_for(key, value = nil)
              if block_given?
                @content_for[key] = yield
                nil
              elsif value
                @content_for[key] = value
                nil
              else
                @content_for[key]
              end
            end

            # Returns the current request's CSRF token.
            #
            # @return [String] the token
            #
            # @raise [Hanami::ComponentLoadError] if the view is not rendered from within a request
            # @raise [Hanami::Action::MissingSessionError] if sessions are not enabled
            #
            # @api public
            # @since 2.1.0
            def csrf_token
              request.session[Hanami::Action::CSRFProtection::CSRF_TOKEN]
            end

            # Returns the session for the current request.
            #
            # @return [Rack::Session::Abstract::SessionHash] the session hash
            #
            # @raise [Hanami::ComponentLoadError] if the view is not rendered from within a request
            # @raise [Hanami::Action::MissingSessionError] if sessions are not enabled
            #
            # @api public
            # @since 2.1.0
            def session
              request.session
            end

            # Returns the flash hash for the current request.
            #
            # @return []
            #
            # @raise [Hanami::ComponentLoadError] if the view is not rendered from within a request
            # @raise [Hanami::Action::MissingSessionError] if sessions are not enabled
            #
            # @api public
            # @since 2.1.0
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
