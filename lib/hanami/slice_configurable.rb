# frozen_string_literal: true

require_relative "errors"

module Hanami
  # Calls `configure_for_slice(slice)` on the extended class whenever it is first
  # subclassed within a module namespace corresponding to a slice.
  #
  # @example
  #   class BaseClass
  #     extend Hanami::SliceConfigurable
  #   end
  #
  #   # slices/main/lib/my_class.rb
  #   module Main
  #     class MyClass < BaseClass
  #       # Will be called with `Main::Slice`
  #       def self.configure_for_slice(slice)
  #         # ...
  #       end
  #     end
  #   end
  #
  # @api private
  # @since 2.0.0
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

            slice = slice_for.(subclass)
            return unless slice

            subclass.configure_for_slice(slice)
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
  end
end
