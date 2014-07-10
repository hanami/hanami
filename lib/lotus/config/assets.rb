module Lotus
  module Config
    # Assets configuration
    #
    # @since 0.1.0
    # @api private
    class Assets
      DEFAULT_DIRECTORY = 'public'.freeze

      def initialize(root, directory)
        @path = case directory
                when :disabled
                when String, NilClass
                  root.join(directory || DEFAULT_DIRECTORY)
                end
      end

      def entries
        if @path.exist?
          @path.children.map {|child| "/#{ child.basename }" }
        else
          []
        end
      end

      def enabled?
        !@path.nil?
      end

      def to_s
        @path.to_s
      end

      alias_method :to_str, :to_s
    end
  end
end
