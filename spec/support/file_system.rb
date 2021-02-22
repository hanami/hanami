# frozen_string_literal: true

module RSpec
  module Support
    class FileSystem
      module Path
        class << self
          def call(path)
            path.split(/\\\//).join(::File::SEPARATOR)
          end
          alias_method :[], :call
        end
      end

      require_relative "./file_system/node"

      def initialize
        @root = Node.new
      end

      def chdir(path)
        path = Path[path]
        directory = find_directory(path)
        raise ArgumentError.new("`#{path}' isn't a directory") if directory.nil?

        current_root = @root
        @root = directory
        yield
      ensure
        @root = current_root
      end

      def mkdir(path)
        path = Path[path]
        node = @root

        for_each_segment(path) do |segment|
          node = node.put(segment)
        end
      end

      def read(path)
        path = Path[path]
        file = find_file(path)
        raise ArgumentError.new("`#{path}' isn't a file") if file.nil?

        file.content
      end

      def write(path, *content)
        path = Path[path]
        node = @root

        for_each_segment(path) do |segment|
          node = node.put(segment)
        end

        node.file!(*content)
      end

      def directory?(path)
        path = Path[path]
        !find_directory(path).nil?
      end

      private

      def for_each_segment(path, &blk)
        segments = path.split(::File::SEPARATOR)
        segments.each(&blk)
      end

      def find_directory(path)
        node = find(path)

        return if node.nil?
        return unless node.directory?

        node
      end

      def find_file(path)
        node = find(path)

        return if node.nil?
        return unless node.file?

        node
      end

      def find(path)
        node = @root

        for_each_segment(path) do |segment|
          break unless node

          node = node.get(segment)
        end

        node
      end
    end
  end
end
