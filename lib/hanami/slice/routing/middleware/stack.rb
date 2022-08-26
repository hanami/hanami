# frozen_string_literal: true

module Hanami
  class Slice
    module Routing
      # @since 2.0.0
      # @api private
      module Middleware
        # Wraps a rack app with a middleware stack
        #
        # We use this class to add middlewares to the rack application generated
        # from {Hanami::Slice::Router}.
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

          # @since 2.0.0
          # @api private
          def initialize
            @prefix = ROOT_PREFIX
            @stack = Hash.new { |hash, key| hash[key] = [] }
          end

          # @since 2.0.0
          # @api private
          def initialize_copy(source)
            super
            @prefix = source.instance_variable_get(:@prefix).dup
            @stack = stack.dup
          end

          # @since 2.0.0
          # @api private
          def use(middleware, *args, before: nil, after: nil, &blk)
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
        end
      end
    end
  end
end
