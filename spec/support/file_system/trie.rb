# frozen_string_literal: true

require_relative "./node"

module RSpec
  module Support
    class FileSystem
      class Trie
        attr_reader :root

        def initialize
          @root = Node.new
        end

        def add_directory(path)
          node = @root
          for_each_segment(path) do |segment|
            node = node.put(segment)
          end
        end

        def add(path, to, constraints)
          node = @root
          for_each_segment(path) do |segment|
            node = node.put(segment, constraints)
          end

          node.leaf!(to)
        end

        def find(path)
          node = @root
          params = {}

          for_each_segment(path) do |segment|
            break unless node

            child, captures = node.get(segment)
            params.merge!(captures) if captures

            node = child
          end

          node
        end

        private

        def for_each_segment(path, &blk)
          _, *segments = path.split(::File::SEPARATOR)
          segments.each(&blk)
        end
      end
    end
  end
end
