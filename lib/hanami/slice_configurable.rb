# frozen_string_literal: true

require_relative "errors"

module Hanami
  # @api private
  module SliceConfigurable
    class << self
      def extended(klass)
        slice_for = method(:slice_for)

        inherited_mod = Module.new do
          define_method(:inherited) do |subclass|
            unless Hanami.application?
              raise ComponentLoadError, "Class #{klass} must be defined within an Hanami application"
            end

            super(subclass)

            subclass.instance_variable_set(:@configured_for_slices, configured_for_slices.dup)

            slice = slice_for.(subclass)
            return unless slice

            unless subclass.configured_for_slice?(slice)
              subclass.configure_for_slice(slice)
              subclass.configured_for_slices << slice
            end
          end
        end

        klass.singleton_class.prepend(inherited_mod)
      end

      private

      def slice_for(klass)
        return unless klass.name

        slices = Hanami.application.slices.to_a + [Hanami.application]

        slices.detect { |slice| klass.name.include?(slice.namespace.to_s) }
      end
    end

    def configure_for_slice(slice); end

    def configured_for_slice?(slice)
      configured_for_slices.include?(slice)
    end

    def configured_for_slices
      @configured_for_slices ||= []
    end
  end
end
