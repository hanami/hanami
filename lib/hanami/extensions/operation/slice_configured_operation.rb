# frozen_string_literal: true

module Hanami
  module Extensions
    module Operation
      class SliceConfiguredOperation < Module
        # @api private
        attr_reader :slice

        def initialize(slice)
          super()
          @slice = slice
        end

        def extended(operation_class)
          define_new
        end

        def inspect
          "#<#{self.class.name}[#{slice.name}>"
        end

        private

        def define_new
          resolve_rom = method(:resolve_rom)

          define_method(:new) do |**kwargs|
            super(
              **kwargs,
              rom: kwargs.fetch(:rom) { resolve_rom.() },
            )
          end
        end

        def resolve_rom
          slice["db.rom"] if slice.key?("db.rom")
        end
      end
    end
  end
end
