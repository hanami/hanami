# frozen_string_literal: true

require "rack/builder"

module Hanami
  class Application
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
          def initialize
            @prefix = ROOT_PREFIX
            @stack = Hash.new { |hash, key| hash[key] = [] }
          end

          # @since 2.0.0
          # @api private
          def use(middleware, *args, &blk)
            @stack[@prefix].push([middleware, args, blk])
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
          def to_rack_app(app) # rubocop:disable Metrics/MethodLength
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
            end.to_app
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
        end
      end
    end
  end
end
