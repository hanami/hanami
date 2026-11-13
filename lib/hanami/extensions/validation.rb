# frozen_string_literal: true

require "dry/validation"
require_relative "validation/messages"

module Hanami
  module Extensions
    # Integrated behavior for `Dry::Validation::Contract` classes within Hanami apps.
    #
    # Contracts defined within a slice's namespace translate their error messages using that slice's
    # `"i18n"` component, so they follow the slice's translation files, default locale and current
    # locale, just like the rest of the app.
    #
    # To opt a contract out, set its messages backend explicitly:
    #
    # @example
    #   module MyApp
    #     class SignupContract < Dry::Validation::Contract
    #       config.messages.backend = :yaml
    #     end
    #   end
    #
    # @see https://hanakai.org/learn/dry/dry-validation
    #
    # @api public
    # @since 3.1.0
    module Validation
      # @api private
      def self.extended(contract_class)
        super

        contract_class.extend(Hanami::SliceConfigurable)
      end

      # @api private
      def configure_for_slice(slice)
        Validation.configure_contract(self, slice)
      end

      class << self
        # Configures the contract class to use the slice's i18n for its messages, unless it (or a
        # superclass) has been explicitly configured with a different messages backend.
        #
        # This must happen before the contract's schema is defined, since dry-schema sets up the
        # messages backend at that point.
        #
        # @api private
        def configure_contract(contract_class, slice)
          messages = contract_class.config.messages

          return if messages.configured?(:backend) && !messages.backend.is_a?(Messages::Builder)

          messages.backend = Messages::Builder.new(slice)
        end

        # Returns a new contract class configured for the slice, with the block evaluated in its
        # class body. Used for anonymous contracts, whose slice cannot be inferred from a name.
        #
        # @api private
        def contract_class(slice, &block)
          Class.new(Dry::Validation::Contract).tap { |klass|
            configure_contract(klass, slice)
            klass.class_exec(&block)
          }
        end
      end
    end
  end
end

Dry::Validation::Contract.extend(Hanami::Extensions::Validation)
