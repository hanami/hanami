# frozen_string_literal: true

module Hanami
  class Configuration
    class Actions
      # Wrapper for application-level configuration of HTTP cookies for Hanami actions.
      # This decorates the hash of cookie options that is otherwise directly configurable
      # on actions, and adds the `enabled?` method to allow `ApplicationAction` to
      # determine whether to include the `Action::Cookies` module.
      #
      # @since 2.0.0
      class Cookies
        attr_reader :options

        def initialize(options)
          @options = options
        end

        def enabled?
          !options.nil?
        end

        def to_h
          options.to_h
        end
      end
    end
  end
end
