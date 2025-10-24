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
    class Router < ::Hanami::Router
      # @api private
      attr_reader :inflector

      # @api private
      attr_reader :middleware_stack

      # @api private
      attr_reader :path_prefix

      # @api private
      # @since 2.0.0
      def initialize(routes:, inflector:, middleware_stack: Routing::Middleware::Stack.new, prefix: ::Hanami::Router::DEFAULT_PREFIX, **kwargs, &blk)
        @path_prefix = Hanami::Router::Prefix.new(prefix)
        @inflector = inflector
        @middleware_stack = middleware_stack
        @resource_key_prefix = []
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

      # Generates RESTful routes for a plural resource.
      #
      # @param name [Symbol] the resource name (plural)
      # @param options [Hash] options for customizing the routes
      # @option options [Array<Symbol>] :only Limit to specific actions
      # @option options [Array<Symbol>] :except Exclude specific actions
      # @option options [String] :to the action key namespace, e.g. "namespace.action"
      # @option options [String] :path the URL path
      # @option options [String, Symbol] :as the route name prefix
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
      # @since 2.3.0
      def resources(name, **options, &block)
        build_resource(name, :plural, options, &block)
      end

      # Generates RESTful routes for a singular resource.
      #
      # @param name [Symbol] the resource name (singular)
      # @param options [Hash] options for customizing the routes
      # @option options [Array<Symbol>] :only limit to specific actions
      # @option options [Array<Symbol>] :except exclude specific actions
      # @option options [String] :to the action key namespace, e.g. "namespace.action"
      # @option options [String] :path the URL path
      # @option options [String, Symbol] :as the route name prefix
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
      # @since 2.3.0
      def resource(name, **options, &block)
        build_resource(name, :singular, options, &block)
      end

      private

      def build_resource(name, type, options, &block)
        key_path = if options[:to]
          options[:to]
        elsif @resource_key_prefix.any?
          "#{@resource_key_prefix.join(CONTAINER_KEY_DELIMITER)}#{CONTAINER_KEY_DELIMITER}#{name}"
        else
          name.to_s
        end

        resource_builder = ResourceBuilder.new(
          name: name,
          type: type,
          options: options.merge(to: key_path),
          inflector: inflector
        )

        resource_builder.add_routes(self)

        resource_scope(name, resource_builder.nested_scope_path, &block) if block
      end

      def resource_scope(resource_name, path, &block)
        @resource_key_prefix.push(resource_name)
        scope(path) do
          instance_eval(&block)
        end
        @resource_key_prefix.pop
      end

      public

      # @api private
      # @since 2.0.0
      def to_rack_app
        middleware_stack.to_rack_app(self)
      end

      # Builds RESTful routes for a resource
      #
      # @api private
      class ResourceBuilder
        ROUTE_CONFIGURATIONS = {
          index: {method: :get, path_suffix: "", name_suffix: ""},
          new: {method: :get, path_suffix: "/new", name_suffix: "new_"},
          create: {method: :post, path_suffix: "", name_suffix: ""},
          show: {method: :get, path_suffix: "/:id", name_suffix: ""},
          edit: {method: :get, path_suffix: "/:id/edit", name_suffix: "edit_"},
          update: {method: :patch, path_suffix: "/:id", name_suffix: ""},
          destroy: {method: :delete, path_suffix: "/:id", name_suffix: ""}
        }.freeze

        PLURAL_ACTIONS = %i[index new create show edit update destroy].freeze
        SINGULAR_ACTIONS = %i[new create show edit update destroy].freeze

        def initialize(name:, type:, options:, inflector:)
          @name = name
          @type = type
          @options = options
          @inflector = inflector

          @action_key_path = options[:to] || name.to_s
          @path = options[:path] || name.to_s
        end

        def add_routes(router)
          actions.each do |action|
            route_config = ROUTE_CONFIGURATIONS[action]
            next unless route_config

            add_route(router, action, route_config)
          end
        end

        def nested_scope_path
          if plural?
            "#{@path}/:#{@inflector.singularize(@path.to_s)}_id"
          else
            @path
          end
        end

        private

        def plural?
          @type == :plural
        end

        def singular?
          !plural?
        end

        def actions
          default_actions = plural? ? PLURAL_ACTIONS : SINGULAR_ACTIONS
          if @options[:only]
            Array(@options[:only]) & default_actions
          elsif @options[:except]
            default_actions - Array(@options[:except])
          else
            default_actions
          end
        end

        def add_route(router, action, route_config)
          router.public_send(
            route_config[:method],
            route_path(route_config[:path_suffix]),
            to: "#{@action_key_path}#{CONTAINER_KEY_DELIMITER}#{action}",
            as: route_name(action, route_config[:name_suffix])
          )
        end

        def route_path(suffix)
          base_path = "/#{@path}"
          suffix = resolve_suffix(suffix)
          suffix.empty? ? base_path : "#{base_path}#{suffix}"
        end

        def route_name(action, prefix)
          base_name = action == :index ? @inflector.pluralize(route_name_base) : route_name_base
          prefix.empty? ? base_name : "#{prefix}#{base_name}"
        end

        def route_name_base
          if @options[:as]
            @options[:as].to_s
          elsif plural?
            @inflector.singularize(@name.to_s)
          else
            @name.to_s
          end
        end

        def resolve_suffix(suffix)
          return "" if suffix.nil? || suffix.empty?

          # For singular resources, remove :id from paths
          return suffix.gsub("/:id", "") if singular?

          suffix
        end
      end
    end
  end
end
