# frozen_string_literal: true

require "dry/validation"
require_relative "validation/messages"

module Hanami
  module Extensions
    # Integrated behavior for `Dry::Validation::Contract` classes within Hanami apps.
    #
    # Contracts defined within a slice's namespace translate their error messages using that
    # slice's `"i18n"` component, so they follow the slice's translation files, default locale and
    # current locale, just like the rest of the app.
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
    # @see https://dry-rb.org/gems/dry-validation/
    #
    # @api public
    # @since 3.1.0
    module Validation
      class << self
        # Returns true if dry-schema accepts custom messages backends. Earlier versions accept only
        # their built-in `:yaml` and `:i18n` backends.
        #
        # @api private
        # @since 3.1.0
        def supported?
          Dry::Schema::Messages.respond_to?(:backend)
        end

        # Configures the contract class to use the slice's i18n for its messages, unless it (or a
        # superclass) has been explicitly configured with a different messages backend.
        #
        # This must happen before the contract's schema is defined, since dry-schema sets up the
        # messages backend at that point.
        #
        # @api private
        # @since 3.1.0
        def configure_contract(contract_class, slice)
          messages = contract_class.config.messages

          return if messages.configured?(:backend) && !messages.backend.is_a?(Messages::Builder)

          messages.backend = Messages::Builder.new(slice)
        end

        # Returns a new contract class configured for the slice, with the block evaluated in its
        # class body. Used for anonymous contracts, whose slice cannot be inferred from a name.
        #
        # @api private
        # @since 3.1.0
        def contract_class(slice, &block)
          Class.new(Dry::Validation::Contract).tap { |klass|
            configure_contract(klass, slice)
            klass.class_exec(&block)
          }
        end

        # @api private
        # @since 3.1.0
        def slice_for(klass)
          return unless klass.name && Hanami.app?

          Hanami.app.with_slices.detect { |slice|
            klass.name.start_with?("#{slice.namespace}#{MODULE_DELIMITER}")
          }
        end
      end

      # Configures named contract subclasses for the slice whose namespace they're defined in.
      #
      # Unlike {Hanami::SliceConfigurable}, contracts defined outside an app (for example by a gem
      # loaded before the app class) are left alone rather than raising an error.
      #
      # @api private
      # @since 3.1.0
      module ContractInherited
        def inherited(subclass)
          super

          slice = Validation.slice_for(subclass)
          Validation.configure_contract(subclass, slice) if slice
        end
      end
    end
  end
end

if Hanami::Extensions::Validation.supported?
  Dry::Validation::Contract.singleton_class.prepend(Hanami::Extensions::Validation::ContractInherited)
end
