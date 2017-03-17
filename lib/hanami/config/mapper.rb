require 'hanami/utils/kernel'

module Hanami
  # @since 0.1.0
  # @api private
  module Config
    # Block or file mapper
    #
    # @since 0.1.0
    # @api private
    class Mapper
      # @api private
      EXTNAME = '.rb'

      # @since 0.1.0
      # @api private
      def initialize(root, path, &blk)
        @path, @blk = path, blk
        @path = root.join(path) if root && path
      end

      # @since 0.1.0
      # @api private
      def to_proc
        return @blk if @blk

        code = realpath.read
        Proc.new { eval(code) }
      end

      private
      # @since 0.1.0
      # @api private
      def realpath
        Utils::Kernel.Pathname("#{ @path }#{ EXTNAME }").realpath
      rescue Errno::ENOENT
        raise ArgumentError, error_message
      end

      # @since 0.1.0
      # @api private
      def error_message
        'You must specify a block or a file.'
      end
    end
  end
end
