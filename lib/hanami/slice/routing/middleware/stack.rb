# frozen_string_literal: true

require "rack/builder"

module Hanami
  class Slice
    module Routing
      # Hanami::Applicatione::Router middleware stack
      #
      # @since 2.0.0
      # @api private
      module Middleware
        # Middleware stack
        #
        # @since 2.0.0
        # @api private
        class Stack
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
