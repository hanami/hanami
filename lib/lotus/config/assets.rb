module Lotus
  module Config
    # Assets configuration
    #
    # @since 0.1.0
    # @api private
    class Assets  < Utils::LoadPaths
      DEFAULT_DIRECTORY = 'public'.freeze

      # @since 0.1.0
      # @api private
      def initialize(root)
        @root = root
        @paths = Array(DEFAULT_DIRECTORY)
      end

      # @since 0.1.0
      # @api private
      def entries
        hash = Hash.new { |k, v| k[v] = [] }
        each do |path|
          if path.exist?
            hash[path.to_s] = path.children.map { |child| "/#{ child.basename }" }
          end
        end
        hash
      end

      # @since 0.2.0
      # @api private
      def any?
        @paths.any?
      end

      protected
      # @since 0.1.0
      # @api private
      def realpath(path)
        @root.join(path).realpath
      end
    end
  end
end
