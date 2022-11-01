# frozen_string_literal: true

require "hanami/middleware"
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
          ROOT_PREFIX = "/"
          private_constant :ROOT_PREFIX

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
            @prefix = ROOT_PREFIX
            @stack = Hash.new { |hash, key| hash[key] = [] }
            @namespaces = [Hanami::Middleware]
          end

          # @since 2.0.0
          # @api private
          def initialize_copy(source)
            super
            @prefix = source.instance_variable_get(:@prefix).dup
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
          def use(spec, *args, before: nil, after: nil, &blk)
            middleware = resolve_middleware_class(spec)
            item = [middleware, args, blk]

            if before
              @stack[@prefix].insert((idx = index_of(before)).zero? ? 0 : idx - 1, item)
            elsif after
              @stack[@prefix].insert(index_of(after) + 1, item)
            else
              @stack[@prefix].push([middleware, args, blk])
            end

            self
          end

          # @since 2.0.0
          # @api private
          def update(other)
            other.stack.each do |prefix, items|
              stack[prefix].concat(items)
            end
            self
          end

          # @since 2.0.0
          # @api private
          def with(path)
            prefix = @prefix
            @prefix = path
            yield
          ensure
            @prefix = prefix
          end

          # @since 2.0.0
          # @api private
          def to_rack_app(app)
            unless Hanami.bundled?("rack")
              raise "Add \"rack\" to your `Gemfile` to run Hanami as a rack app"
            end

            require "rack/builder"

            s = self

            Rack::Builder.new do
              s.each do |prefix, stack|
                s.mapped(self, prefix) do
                  stack.each do |middleware, args, blk|
                    use(middleware, *args, &blk)
                  end
                end

                run app
              end
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
            if prefix == ROOT_PREFIX
              builder.instance_eval(&blk)
            else
              builder.map(prefix, &blk)
            end
          end

          private

          # @since 2.0.0
          def index_of(middleware)
            @stack[@prefix].index { |(m, *)| m.equal?(middleware) }
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
