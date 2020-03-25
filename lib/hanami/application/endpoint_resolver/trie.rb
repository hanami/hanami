# frozen_string_literal: true

require "hanami/application/endpoint_resolver/node"

module Hanami
  class Application
    class EndpointResolver
      # Endpoint resolver trie to register slices
      #
      # @api private
      # @since 2.0.0
      class Trie
        # @api private
        # @since 2.0.0
        def initialize
          @root = Node.new
        end

        # @api private
        # @since 2.0.0
        def add(path, name)
          node = @root
          for_each_segment(path) do |segment|
            node = node.put(segment)
          end

          node.leaf!(name)
        end

        # @api private
        # @since 2.0.0
        def find(path)
          node = @root

          for_each_segment(path) do |segment|
            break unless node

            node = node.get(segment)
          end

          return node.slice if node&.leaf?

          nil
        end

        private

        # @api private
        # @since 2.0.0
        def for_each_segment(path, &blk)
          _, *segments = path.split(/\//)
          segments.each(&blk)
        end
      end
    end
  end
end
