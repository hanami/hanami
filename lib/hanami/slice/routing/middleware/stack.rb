# frozen_string_literal: true

require "hanami/router"
require "hanami/middleware"
require "hanami/middleware/app"
require "hanami/errors"

module Hanami
  class Slice
    module Routing
      # @since 2.0.0
      # @api private
      module Middleware
        # Wraps a rack app with a middleware stack
        #
        # We use this class to add middlewares to the rack application generated from
        # {Hanami::Slice::Router}.
        #
        # ```
        # stack = Hanami::Slice::Routing::Middleware::Stack.new
        # stack.use(Rack::ContentType, "text/html")
        # stack.to_rack_app(a_rack_app)
        # ```
        #
        # Middlewares can be mounted on specific paths:
        #
        # ```
        # stack.with("/api") do
        #   stack.use(Rack::ContentType, "application/json")
        # end
        # ```
        #
        # @see Hanami::Config#middleware
        #
        # @since 2.0.0
        # @api private
        class Stack
          include Enumerable

          # @since 2.0.0
          # @api private
          attr_reader :stack

          # Returns an array of Ruby namespaces from which to load middleware classes specified by
          # symbol names given to {#use}.
          #
          # Defaults to `[Hanami::Middleware]`.
          #
          # @return [Array<Object>]
          #
          # @api public
          # @since 2.0.0
          attr_reader :namespaces

          # @since 2.0.0
          # @api private
          def initialize
            @stack = Hash.new { |hash, key| hash[key] = [] }
            @namespaces = [Hanami::Middleware]
          end

          # @since 2.0.0
          # @api private
          def initialize_copy(source)
            super
            @stack = stack.dup
            @namespaces = namespaces.dup
          end

          # Adds a middleware to the stack.
          #
          # @example
          #   # Using a symbol name; adds Hanami::Middleware::BodyParser.new([:json])
          #   middleware.use :body_parser, :json
          #
          #   # Using a class name
          #   middleware.use MyMiddleware
          #
          #   # Adding a middleware before or after others
          #   middleware.use MyMiddleware, before: SomeMiddleware
          #   middleware.use MyMiddleware, after: OtherMiddleware
          #
          # @param spec [Symbol, Class] the middleware name or class name
          # @param args [Array, nil] Arguments to pass to the middleware's `.new` method
          # @param before [Class, nil] an optional (already added) middleware class to add the
          #   middleware before
          # @param after [Class, nil] an optional (already added) middleware class to add the
          #   middleware after
          #
          # @return [self]
          #
          # @api public
          # @since 2.0.0
          def use(spec, *args, path_prefix: ::Hanami::Router::DEFAULT_PREFIX, before: nil, after: nil, **kwargs, &blk)
            middleware = resolve_middleware_class(spec)
            item = [middleware, args, kwargs, blk]

            if before
              @stack[path_prefix].insert((idx = index_of(before, path_prefix)).zero? ? 0 : idx - 1, item)
            elsif after
              @stack[path_prefix].insert(index_of(after, path_prefix) + 1, item)
            else
              @stack[path_prefix].push(item)
            end

            self
          end

          # @since 2.0.0
          # @api private
          def update(other)
            other.stack.each do |path_prefix, items|
              stack[path_prefix].concat(items)
            end
            self
          end

          # @since 2.0.0
          # @api private
          def to_rack_app(app)
            unless Hanami.bundled?("rack")
              raise "Add \"rack\" to your `Gemfile` to run Hanami as a rack app"
            end

            mapping = to_hash
            return app if mapping.empty?

            Hanami::Middleware::App.new(app, mapping)
          end

          # @since 2.0.0
          # @api private
          def to_hash
            @stack.each_with_object({}) do |(path, _), result|
              result[path] = stack_for(path)
            end
          end

          # @since 2.0.0
          # @api private
          def empty?
            @stack.empty?
          end

          # @since 2.0.0
          # @api private
          def each(&blk)
            @stack.each(&blk)
          end

          # @since 2.0.0
          # @api private
          def mapped(builder, prefix, &blk)
            if prefix == ::Hanami::Router::DEFAULT_PREFIX
              builder.instance_eval(&blk)
            else
              builder.map(prefix, &blk)
            end
          end

          private

          # @since 2.0.0
          def index_of(middleware, path_prefix)
            @stack[path_prefix].index { |(m, *)| m.equal?(middleware) }
          end

          # @since 2.0.0
          # @api private
          def stack_for(current_path)
            @stack.each_with_object([]) do |(path, stack), result|
              next unless current_path.start_with?(path)

              result.push(stack)
            end.flatten(1)
          end

          # @since 2.0.0
          def resolve_middleware_class(spec)
            case spec
            when Symbol then load_middleware_class(spec)
            when Class, Module then spec
            else
              if spec.respond_to?(:call)
                spec
              else
                raise UnsupportedMiddlewareSpecError, spec
              end
            end
          end

          # @since 2.0.0
          def load_middleware_class(spec)
            begin
              require "hanami/middleware/#{spec}"
            rescue LoadError # rubocop:disable Lint/SuppressedException
            end

            # FIXME: Classify must use App inflector
            class_name = Hanami::Utils::String.classify(spec.to_s)
            namespace = namespaces.detect { |ns| ns.const_defined?(class_name) }

            if namespace
              namespace.const_get(class_name)
            else
              raise(
                UnsupportedMiddlewareSpecError,
                "Failed to find corresponding middleware class for `#{spec}` in #{namespaces.join(', ')}"
              )
            end
          end
        end
      end
    end
  end
end
