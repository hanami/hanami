# frozen_string_literal: true

module Hanami
  class Application
    module Routing
      class Resolver
        # Endpoint resolver node to register slices in a tree
        #
        # @api private
        # @since 2.0.0
        class Node
          # @api private
          # @since 2.0.0
          attr_reader :slice

          # @api private
          # @since 2.0.0
          def initialize
            @slice = nil
            @children = {}
          end

          # @api private
          # @since 2.0.0
          def put(segment)
            @children[segment] ||= self.class.new
          end

          # @api private
          # @since 2.0.0
          def get(segment)
            @children.fetch(segment) { self if leaf? }
          end

          # @api private
          # @since 2.0.0
          def leaf!(slice)
            @slice = slice
          end

          # @api private
          # @since 2.0.0
          def leaf?
            @slice
          end
        end
      end
    end
  end
end
