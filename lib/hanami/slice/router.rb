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
      def initialize(routes:, inflector:, middleware_stack: Routing::Middleware::Stack.new, prefix: ::Hanami::Router::DEFAULT_PREFIX, **kwargs, &blk)
        @path_prefix = Hanami::Router::Prefix.new(prefix)
        @inflector = inflector
        @middleware_stack = middleware_stack
        @resource_scope = []
        instance_eval(&blk)
        super(**kwargs, &routes)
      end

      # @api private
      def freeze
        return self if frozen?

        remove_instance_variable(:@middleware_stack)
        super
      end

      # @api private
      def to_rack_app
        middleware_stack.to_rack_app(self)
      end

      # @api private
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
      def slice(slice_name, at:, as: nil, &blk)
        blk ||= @resolver.find_slice(slice_name).routes

        prev_resolver = @resolver
        @resolver = @resolver.to_slice(slice_name)

        scope(at, as:, &blk)
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
        resource_builder = ResourceBuilder.new(
          name: name,
          type: type,
          resource_scope: @resource_scope,
          options: options,
          inflector: inflector
        )

        resource_builder.add_routes(self)

        resource_scope(resource_builder, &block) if block
      end

      # @api private
      def resource_scope(resource_builder, &block)
        @resource_scope.push(resource_builder.name)
        scope(resource_builder.scope_path, as: inflector.singularize(resource_builder.name)) do
          instance_eval(&block)
        end
      ensure
        @resource_scope.pop
      end

      # Builds RESTful routes for a resource
      #
      # @api private
      class ResourceBuilder
        ROUTE_OPTIONS = {
          index: {method: :get},
          new: {method: :get, path_suffix: "/new", name_prefix: "new"},
          create: {method: :post},
          show: {method: :get, path_suffix: "/:id"},
          edit: {method: :get, path_suffix: "/:id/edit", name_prefix: "edit"},
          update: {method: :patch, path_suffix: "/:id"},
          destroy: {method: :delete, path_suffix: "/:id"}
        }.freeze

        PLURAL_ACTIONS = %i[index new create show edit update destroy].freeze
        SINGULAR_ACTIONS = %i[new create show edit update destroy].freeze

        attr_reader :name

        def initialize(name:, type:, resource_scope:, options:, inflector:)
          @name = name
          @type = type
          @resource_scope = resource_scope
          @options = options
          @inflector = inflector

          @path = options[:path] || name.to_s
        end

        def add_routes(router)
          actions.each do |action|
            add_route(router, action, ROUTE_OPTIONS.fetch(action))
          end
        end

        def scope_path
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
          path = route_path(route_config[:path_suffix])

          router.public_send(
            route_config[:method],
            path,
            to: "#{key_path_base}#{CONTAINER_KEY_DELIMITER}#{action}",
            as: route_name(action, route_config[:name_prefix])
          )
        end

        def route_path(suffix)
          base_path = "/#{@path}"
          suffix = normalize_suffix(suffix)
          suffix.empty? ? base_path : "#{base_path}#{suffix}"
        end

        def normalize_suffix(suffix)
          return "" if suffix.nil? || suffix.empty?

          # For singular resources, remove :id from paths
          return suffix.gsub("/:id", "") if singular?

          suffix
        end

        def key_path_base
          @key_path ||=
            if @options[:to]
              @options[:to]
            else
              @name.to_s.then { |name|
                next name unless @resource_scope.any?

                prefix = @resource_scope.join(CONTAINER_KEY_DELIMITER)
                "#{prefix}#{CONTAINER_KEY_DELIMITER}#{name}"
              }
            end
        end

        def route_name(action, prefix)
          name = route_name_base
          name = @inflector.pluralize(name) if action == :index

          [prefix, name]
        end

        def route_name_base
          @route_name_base ||=
            if @options[:as]
              @options[:as].to_s
            elsif plural?
              @inflector.singularize(@name.to_s)
            else
              @name.to_s
            end
        end
      end
    end
  end
end
