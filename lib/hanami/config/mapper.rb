require 'hanami/utils/kernel'

module Hanami
  module Config
    # Define a mapping for Hanami::Model
    #
    # @since 0.1.0
    # @api private
    class Mapper
      EXTNAME = '.rb'

      def initialize(root, path, &blk)
        @path, @blk = path, blk
        @path = root.join(path) if root && path
      end

      def to_proc
        return @blk if @blk

        code = realpath.read
        Proc.new { eval(code) }
      end

      private
      def realpath
        Utils::Kernel.Pathname("#{ @path }#{ EXTNAME }").realpath
      rescue Errno::ENOENT
        raise ArgumentError, error_message
      end

      def error_message
        'You must specify a block or a file.'
      end
    end
  end
end
