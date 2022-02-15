# frozen_string_literal: true

module Hanami
  class Application
    # @api private
    class SliceRegistrar
      attr_reader :slices
      private :slices

      def initialize
        @slices = {}
      end

      def register(name, slice_class = nil, &block)
        # TODO: real error class
        raise "Slice +#{name}+ already registered" if slices.key?(name.to_sym)
        # TODO: raise error unless name meets format (i.e. single level depth only)

        slices[name.to_sym] = slice_class || Slice.build_slice(name, &block)
      end

      def [](name)
        slices.fetch(name) do
          raise "Slice #{name} not found"
        end
      end

      def each(&block)
        slices.each_value(&block)
      end

      def to_a
        slices.values
      end
    end
  end
end
