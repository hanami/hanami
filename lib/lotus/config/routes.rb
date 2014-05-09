require 'lotus/utils/kernel'

module Lotus
  module Config
    class Routes
      EXTNAME = '.rb'

      def initialize(path, &blk)
        @path, @blk = path, blk
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
        raise ArgumentError, 'You must specify a block or a file for routes definitions.'
      end
    end
  end
end
