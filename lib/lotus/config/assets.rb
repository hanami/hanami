module Lotus
  module Config
    # Assets configuration
    #
    # @since 0.1.0
    # @api private
    class Assets
      DEFAULT_DIRECTORY = 'public'.freeze

      def initialize(root)
        @root = root
        @paths = []
      end

      def <<(directories)
        directories.each do |directory|
          paths << root.join(directory)
        end
      end

      def entries
        paths.flat_map do |path|
          if path.exist?
            path.children.map {|child| "/#{ child.basename }" }
          end
        end.compact
      end

      def enabled?
        paths.any?
      end

      def to_s
        paths.last.to_s
      end

      attr_reader :paths
      alias_method :to_str, :to_s

      private

      def default_path
        root.join(DEFAULT_DIRECTORY)
      end

      attr_reader :root
    end
  end
end
