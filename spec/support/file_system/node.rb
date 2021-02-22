# frozen_string_literal: true

module RSpec
  module Support
    class FileSystem
      class Node
        attr_reader :content

        def initialize
          @fixed = nil
          @content = nil
        end

        # @api private
        # @since 2.0.0
        def put(segment)
          @fixed ||= {}
          @fixed[segment] ||= self.class.new
        end

        # @api private
        # @since 2.0.0
        #
        def get(segment)
          @fixed&.fetch(segment, nil)
        end

        def directory?
          !file?
        end

        # @api private
        # @since 2.0.0
        def file?
          !@content.nil?
        end

        # @api private
        # @since 2.0.0
        def file!(*content)
          @content = content.join($/)
        end

        private

        # @api private
        # @since 2.0.0
        def segment_for(segment, constraints)
          Segment.fabricate(segment, **constraints)
        end

        # @api private
        # @since 2.0.0
        def fixed?(matcher)
          matcher.names.empty?
        end
      end
    end
  end
end
