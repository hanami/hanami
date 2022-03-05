# frozen_string_literal: true

module Hanami
  module SliceConfigurableClass
    class << self
      def extended(klass)
        unless Hanami.application?
          raise "Class #{klass} must be defined within an Hanami application"
        end

        unless Hanami.application.prepared?
          raise "Hanami application must be prepared"
        end

        slice_for = method(:slice_for)
        klass.define_singleton_method(:inherited) do |subclass|
          super(subclass)

          if subclass.respond_to?(:configure_for_slice)
            slice = slice_for.(subclass)
            # TODO: only run this when the slice has changed vs the subclass.superclass
            subclass.configure_for_slice(slice_for.(subclass))
          end
        end
      end

      private

      def slice_for(klass)
        return unless klass.name

        slices = Hanami.application.slices.to_a + [Hanami.application]

        slices.detect { |slice| klass.name.include?(slice.namespace.to_s) }
      end
    end
  end
end
