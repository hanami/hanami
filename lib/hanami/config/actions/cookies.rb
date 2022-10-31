# frozen_string_literal: true

module Hanami
  class Config
    class Actions
      # Wrapper for app-level config of HTTP cookies for Hanami actions.
      #
      # This decorates the hash of cookie options that is otherwise directly configurable on
      # actions, and adds the `enabled?` method to allow app base action to determine whether to
      # include the `Action::Cookies` module.
      #
      # @api public
      # @since 2.0.0
      class Cookies
        # Returns the cookie options.
        #
        # @return [Hash]
        #
        # @api public
        # @since 2.0.0
        attr_reader :options

        # Returns a new `Cookies`.
        #
        # You should not need to initialize this class directly. Instead use
        # {Hanami::Config::Actions#cookies}.
        #
        # @api private
        # @since 2.0.0
        def initialize(options)
          @options = options
        end

        # Returns true if any cookie options have been provided.
        #
        # @return [Boolean]
        #
        # @api public
        # @since 2.0.0
        def enabled?
          !options.nil?
        end

        # Returns the cookie options.
        #
        # If no options have been provided, returns an empty hash.
        #
        # @return [Hash]
        #
        # @api public
        def to_h
          options.to_h
        end
      end
    end
  end
end
