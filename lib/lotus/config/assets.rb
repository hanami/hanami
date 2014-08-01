module Lotus
  module Config
    # Assets configuration
    #
    # @since 0.1.0
    # @api private
    class Assets
      class Path
        def initialize(path)
          @path = path
        end

        def entries
          if path.exist?
            path.children.map {|child| "/#{ child.basename }" }
          else
            []
          end
        end

        def to_s
          path.to_s
        end

        def ==(other)
          self.to_s == other.path.to_s
        end

        attr_accessor :path
        alias_method :to_str, :to_s
      end

      DEFAULT_DIRECTORY = 'public'.freeze

      def initialize(root, enabled=true)
        @enabled = enabled
        @root = root
        @paths = []
      end

      def <<(directories)
        directories.each do |directory|
          @paths << Path.new(@root.join(directory))
        end
      end

      def entries
        paths.flat_map do |path|
          path.entries
        end.compact
      end

      def enabled?
        @enabled
      end

      def to_s
        paths.map(&:to_s)
      end

      def paths
        @paths.any? ? @paths : [default_path]
      end

      def default_path
        Path.new(@root.join(DEFAULT_DIRECTORY))
      end
    end
  end
end
