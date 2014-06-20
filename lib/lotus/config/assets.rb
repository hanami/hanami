module Lotus
  module Config
    class Assets
      DEFAULT_DIRECTORY = 'public'.freeze

      def initialize(root, directory)
        @path = root.join directory || DEFAULT_DIRECTORY
      end

      def entries
        if @path.exist?
          @path.children.map {|child| "/#{ child.basename }" }
        else
          []
        end
      end

      def to_s
        @path.to_s
      end

      def to_str
        to_s
      end
    end
  end
end
