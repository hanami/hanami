# frozen_string_literal: true

require "hanami/router"

module Hanami
  class Slice
    # `Hanami::Router` subclass with enhancements for use within Hanami apps.
    #
    # This is loaded from Hanami apps and slices and made available as their
    # {Hanami::Slice::ClassMethods#router router}.
    #
    # @api private
    # @since 2.0.0
    class Router < ::Hanami::Router
      # @api private
      # @since 2.0.0
      attr_reader :middleware_stack

      # @api private
      # @since 2.0.0
      attr_reader :path_prefix

      # @api private
      # @since 2.0.0
      def initialize(routes:, inflector:, middleware_stack: Routing::Middleware::Stack.new, prefix: ::Hanami::Router::DEFAULT_PREFIX, **kwargs, &blk)
        @path_prefix = Hanami::Router::Prefix.new(prefix)
        @inflector = inflector
        @middleware_stack = middleware_stack
        instance_eval(&blk)
        super(**kwargs, &routes)
      end

      # @api private
      # @since 2.0.0
      def freeze
        return self if frozen?

        remove_instance_variable(:@middleware_stack)
        super
      end

      # @api private
      # @since 2.0.0
      def use(*args, **kwargs, &blk)
        middleware_stack.use(*args, **kwargs.merge(path_prefix: path_prefix.to_s), &blk)
      end

      # Yields a block for routes to resolve their action components from the given slice.
      #
      # An optional URL prefix may be supplied with `at:`.
      #
      # @example
      #   # config/routes.rb
      #
      #   module MyApp
      #     class Routes < Hanami::Routes
      #       slice :admin, at: "/admin" do
      #         # Will route to the "actions.posts.index" component in Admin::Slice
      #         get "posts", to: "posts.index"
      #       end
      #     end
      #   end
      #
      # @param slice_name [Symbol] the slice's name
      # @param at [String, nil] optional URL prefix for the routes
      #
      # @api public
      # @since 2.0.0
      def slice(slice_name, at:, &blk)
        blk ||= @resolver.find_slice(slice_name).routes

        prev_resolver = @resolver
        @resolver = @resolver.to_slice(slice_name)

        scope(at, &blk)
      ensure
        @resolver = prev_resolver
      end

      # Generate RESTful routes for a plural resource
      # @param name [Symbol] The resource name (plural)
      # @param options [Hash] Options for customizing the routes
      # @option options [Array<Symbol>] :only Limit to specific actions
      # @option options [Array<Symbol>] :except Exclude specific actions
      # @option options [String] :to Override the action path (supports "namespace.action" or "namespace/action")
      # @option options [String] :path Override the URL path
      # @option options [String, Symbol] :as Override the route name prefix
      #
      # @example
      #   resources :users
      #   # Generates:
      #   # GET    /users          users.index
      #   # GET    /users/new      users.new
      #   # POST   /users          users.create
      #   # GET    /users/:id      users.show
      #   # GET    /users/:id/edit users.edit
      #   # PATCH  /users/:id      users.update
      #   # DELETE /users/:id      users.destroy
      #
      # @api public
      # @since x.x.x
      def resources(name, **options, &block)
        resource_builder = ResourceBuilder.new(
          router: self,
          inflector: @inflector,
          name: name,
          type: :plural,
          options: options
        )

        resource_builder.build_routes

        if block_given?
          nested_context = NestedResourceContext.new(self, @inflector, resource_builder.path)
          nested_context.instance_eval(&block)
        end
      end

      # Generate RESTful routes for a singular resource
      # @param name [Symbol] The resource name (singular)
      # @param options [Hash] Options for customizing the routes
      # @option options [Array<Symbol>] :only Limit to specific actions
      # @option options [Array<Symbol>] :except Exclude specific actions
      # @option options [String] :to Override the action path (supports "namespace.action" or "namespace/action")
      # @option options [String] :path Override the URL path
      # @option options [String, Symbol] :as Override the route name
      #
      # @example
      #   resource :profile
      #   # Generates (singular, no index):
      #   # GET    /profile/new    profile.new
      #   # POST   /profile        profile.create
      #   # GET    /profile        profile.show
      #   # GET    /profile/edit   profile.edit
      #   # PATCH  /profile        profile.update
      #   # DELETE /profile        profile.destroy
      #
      # @api public
      # @since x.x.x
      def resource(name, **options, &block)
        resource_builder = ResourceBuilder.new(
          router: self,
          inflector: @inflector,
          name: name,
          type: :singular,
          options: options
        )

        resource_builder.build_routes

        if block_given?
          nested_context = NestedResourceContext.new(self, @inflector, resource_builder.path)
          nested_context.instance_eval(&block)
        end
      end

      # @api private
      # @since 2.0.0
      def to_rack_app
        middleware_stack.to_rack_app(self)
      end

      # Builds RESTful routes for a resource
      # @api private
      # @since x.x.x
      class ResourceBuilder
        attr_reader :router, :inflector, :name, :type, :options, :action_path, :path, :route_name

        def initialize(router:, inflector:, name:, type:, options:)
          @router = router
          @inflector = inflector
          @name = name
          @type = type
          @options = options
          @action_path = normalize_action_path(options[:to] || name.to_s)
          @path = options[:path] || name.to_s
          @route_name = determine_route_name
        end

        def normalize_action_path(action_path)
          # Convert namespace/action format to namespace.action format
          action_path.to_s.gsub("/", ".")
        end

        def build_routes
          allowed_actions.each do |action|
            route_config = ROUTE_CONFIGURATIONS[action]
            next unless route_config

            build_route(action, route_config)
          end
        end

        private

        ROUTE_CONFIGURATIONS = {
          index: {method: :get, path_suffix: "", name_suffix: ""},
          new: {method: :get, path_suffix: "/new", name_suffix: "new_"},
          create: {method: :post, path_suffix: "", name_suffix: ""},
          show: {method: :get, path_suffix: "/:id", name_suffix: ""},
          edit: {method: :get, path_suffix: "/:id/edit", name_suffix: "edit_"},
          update: {method: :patch, path_suffix: "/:id", name_suffix: ""},
          destroy: {method: :delete, path_suffix: "/:id", name_suffix: ""}
        }.freeze

        def determine_route_name
          if options[:as]
            options[:as].to_s
          elsif type == :plural
            @inflector.singularize(name.to_s)
          else
            name.to_s
          end
        end

        def allowed_actions
          default_actions = type == :plural ? PLURAL_ACTIONS : SINGULAR_ACTIONS
          ActionFilter.filter(default_actions, options)
        end

        PLURAL_ACTIONS = %i[index new create show edit update destroy].freeze
        SINGULAR_ACTIONS = %i[new create show edit update destroy].freeze

        def build_route(action, config)
          configs = config.is_a?(Array) ? config : [config]

          configs.each do |route_config|
            route_path = build_route_path(route_config[:path_suffix])
            route_name = build_route_name(action, route_config[:name_suffix])
            action_target = "#{action_path}.#{action}"

            router.public_send(
              route_config[:method],
              route_path,
              to: action_target,
              as: route_name
            )
          end
        end

        def build_route_path(suffix)
          base_path = "/#{path}"
          suffix = resolve_suffix(suffix)
          suffix.empty? ? base_path : "#{base_path}#{suffix}"
        end

        def build_route_name(action, prefix)
          base_name = action == :index ? @inflector.pluralize(route_name) : route_name
          prefix.empty? ? base_name : "#{prefix}#{base_name}"
        end

        def resolve_suffix(suffix)
          return "" if suffix.nil? || suffix.empty?

          # For singular resources, remove :id from paths
          if type == :singular
            return suffix.gsub("/:id", "")
          end

          suffix
        end
      end

      # Filters actions based on :only and :except options
      # @api private
      # @since x.x.x
      class ActionFilter
        def self.filter(default_actions, options)
          if options[:only]
            Array(options[:only]) & default_actions
          elsif options[:except]
            default_actions - Array(options[:except])
          else
            default_actions
          end
        end
      end

      # Context for handling nested resources
      # @api private
      # @since x.x.x
      class NestedResourceContext
        def initialize(router, inflector, parent_path)
          @router = router
          @inflector = inflector
          @parent_path = parent_path
        end

        def resources(name, **options)
          build_nested_resource(name, :plural, options)
        end

        def resource(name, **options)
          build_nested_resource(name, :singular, options)
        end

        private

        def build_nested_resource(name, type, options)
          nested_builder = NestedResourceBuilder.new(
            router: @router,
            inflector: @inflector,
            parent_path: @parent_path,
            name: name,
            type: type,
            options: options
          )

          nested_builder.build_routes
        end
      end

      # Builds nested resource routes
      # @api private
      # @since x.x.x
      class NestedResourceBuilder < ResourceBuilder
        attr_reader :parent_path, :parent_name, :inflector

        def initialize(router:, inflector:, parent_path:, name:, type:, options:)
          super(router: router, inflector: inflector, name: name, type: type, options: options)
          @inflector = inflector
          @parent_path = parent_path
          @parent_name = inflector.singularize(parent_path.to_s)
        end

        private

        def build_route_path(suffix)
          base_path = "/#{parent_path}/:#{parent_name}_id/#{path}"
          suffix = resolve_suffix(suffix)
          suffix.empty? ? base_path : "#{base_path}#{suffix}"
        end

        def build_route_name(action, prefix)
          base_name = action == :index ? @inflector.pluralize(route_name) : route_name
          nested_name = "#{parent_name}_#{base_name}"
          prefix.empty? ? nested_name : "#{prefix}#{nested_name}"
        end
      end
    end
  end
end
