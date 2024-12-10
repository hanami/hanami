# frozen_string_literal: true

module Hanami
  module CygUtils
    # Ordered file list, consistent across operating systems
    #
    # @since 0.9.0
    module FileList
      # Returns an ordered list of files, consistent across operating systems
      #
      # It has the same signature of <tt>Dir.glob</tt>, it just guarantees to
      # order the results before to return them.
      #
      # @since 0.9.0
      #
      # @see https://ruby-doc.org/core/Dir.html#method-c-glob
      def self.[](*args)
        Dir.glob(*args).sort!
      end
    end
  end
end
