# frozen_string_literal: true

module Hanami
  module Console
    module Plugins
      class SliceReaders < Module
        def initialize(ctx)
          ctx.application.slices.each do |slice|
            define_method(slice.name) do
              SliceDelegator.new(slice)
            end
          end
        end

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
