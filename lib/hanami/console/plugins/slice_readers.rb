# frozen_string_literal: true

require "delegate"

module Hanami
  module Console
    module Plugins
      # @api private
      # @since 2.0.0
      class SliceReaders < Module
        def initialize(ctx)
          ctx.application.slices.each do |(name, slice)|
            define_method(name) do
              SliceDelegator.new(slice)
            end
          end
        end

        # @api private
        # @since 2.0.0
        class SliceDelegator < SimpleDelegator
          def method_missing(name, *args, &block)
            if args.empty? && key?(name)
              self[name]
            else
              super
            end
          end

          private

          def respond_to_missing?(name)
            key?(name)
          end
        end
      end
    end
  end
end
