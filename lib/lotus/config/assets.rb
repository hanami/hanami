module Lotus
  module Config
    # Assets configuration
    #
    # @since x.x.x
    # @api private
    class Assets  < Utils::LoadPaths
      DEFAULT_DIRECTORY = 'public'.freeze

      def initialize(root)
        @root = root
        @paths = Array(DEFAULT_DIRECTORY)
      end

      def entries
        hash = Hash.new { |k, v| k[v] = [] }
        each do |path|
          if path.exist?
            hash[path.to_s] = path.children.map { |child| "/#{ child.basename }" }
          end
        end
        hash
      end

      def any?
        @paths.any?
      end

      protected
      def realpath(path)
        @root.join(path).realpath
      end
    end
  end
end
