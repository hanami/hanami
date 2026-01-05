# frozen_string_literal: true

module Hanami
  module Extensions
    module Operation
      # Extends operations to support the database.
      #
      # Add an initializer accepting a `rom:` dependency, which is supplied automatically from the
      # `"db.rom"` component in the operation's slice.
      #
      # @api private
      class SliceConfiguredDBOperation < Module
        attr_reader :slice

        def initialize(slice)
          super()
          @slice = slice
        end

        def extended(operation_class)
          require "dry/operation/extensions/rom"
          operation_class.include Dry::Operation::Extensions::ROM

          operation_class.include InstanceMethods
          operation_class.include SliceInstanceMethods.new(slice)
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

        module InstanceMethods
          attr_reader :rom

          def initialize(rom:, **)
            super()
            @rom = rom
          end
        end

        class SliceInstanceMethods < Module
          attr_reader :slice

          def initialize(slice)
            super()
            @slice = slice
          end

          def included(operation_class)
            define_transaction
          end

          private

          def define_transaction
            slice = self.slice
            define_method(:transaction) do |**kwargs, &block|
              unless rom
                msg = <<~TEXT.strip
                  A configured db for #{slice} is required to run transactions.
                TEXT
                raise Hanami::ComponentLoadError, msg
              end

              super(**kwargs, &block)
            end
          end
        end
      end
    end
  end
end
