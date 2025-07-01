# frozen_string_literal: true

require "dry/operation"

module Hanami
  module Extensions
    # Integrated behavior for `Dry::Operation` classes within Hanami apps.
    #
    # @see https://github.com/dry-rb/dry-operation
    #
    # @api public
    # @since 2.2.0
    module Operation
      # @api private
      # @since 2.2.0
      def self.included(operation_class)
        super

        operation_class.extend(Hanami::SliceConfigurable)
        operation_class.extend(ClassMethods)
        operation_class.prepend(InstanceMethods)
      end

      # @api private
      # @since 2.2.0
      module ClassMethods
        # @api private
        # @since 2.2.0
        def configure_for_slice(slice)
          return unless Hanami.bundled?("hanami-db")

          extend SliceConfiguredOperation.new(slice)
        end

        # @api private
        # @since 2.2.0
        def inherited(subclass)
          super

          return unless subclass.superclass == self
          return unless Hanami.bundled?("hanami-db")

          require "dry/operation/extensions/rom"
          subclass.include Dry::Operation::Extensions::ROM
        end
      end

      # @api public
      # @since x.x.x
      module InstanceMethods
        # @api private
        attr_reader :rom

        # @api public
        # @since x.x.x
        def initialize(rom: nil, **kwargs)
          @rom = rom
        end
      end
    end
  end
end

Dry::Operation.include(Hanami::Extensions::Operation)
