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
      require_relative "operation/slice_configured_db_operation"

      # @api private
      def self.extended(operation_class)
        super

        operation_class.extend(Hanami::SliceConfigurable)
      end

      # private

      # @api private
      def configure_for_slice(slice)
        extend SliceConfiguredDBOperation.new(slice) if Hanami.bundled?("hanami-db")
      end
    end
  end
end

Dry::Operation.extend(Hanami::Extensions::Operation)
