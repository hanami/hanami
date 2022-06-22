# frozen_string_literal: true

require "dry/configurable"
require "dry/core/constants"

module Hanami
  # Application settings
  #
  # Users are expected to inherit from this class to define their application
  # settings.
  #
  # @example
  #   # config/settings.rb
  #   # frozen_string_literal: true
  #
  #   require "hanami/settings"
  #   require "my_app/types"
  #
  #   module MyApp
  #     class Settings < Hanami::Settings
  #       setting :database_url
  #       setting :feature_flag, default: false, constructor: Types::Params::Bool
  #     end
  #   end
  #
  # Settings are defined with
  # [dry-configurable](https://dry-rb.org/gems/dry-configurable/), so you can
  # take a look there to see the supported syntax.
  #
  # Users work with an instance of this class made available within the
  # `settings` key in the container. The instance gets its settings populated
  # from a configurable store, which defaults to
  # {Hanami::Settings::DotenvStore}.
  #
  # A different store can be set through the `settings_store` Hanami
  # configuration option. All it needs to do is implementing a `#fetch` method
  # with the same signature as `Hash#fetch`.
  #
  # @see Hanami::Settings::DotenvStore
  # @since 2.0.0
  class Settings
    # Exception for errors in the definition of settings.
    #
    # Its message collects all the individual errors that can be raised for
    # each setting.
    InvalidSettingsError = Class.new(StandardError) do
      def initialize(errors)
        @errors = errors
      end

      def to_s
        <<~STR.strip
          Could not initialize settings. The following settings were invalid:

          #{@errors.map { |setting, message| "#{setting}: #{message}" }.join("\n")}
        STR
      end
    end

    # @api private
    EMPTY_STORE = Dry::Core::Constants::EMPTY_HASH

    include Dry::Configurable

    # @api private
    def initialize(store = EMPTY_STORE)
      errors = config._settings.map(&:name).reduce({}) do |errs, name|
        public_send("#{name}=", store.fetch(name) { Dry::Core::Constants::Undefined })
        errs
      rescue => e # rubocop:disable Style/RescueStandardError
        errs.merge(name => e)
      end

      raise InvalidSettingsError, errors if errors.any?
    end

    private

    def method_missing(name, *args, &block)
      if config.respond_to?(name)
        config.send(name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, _include_all = false)
      config.respond_to?(name) || super
    end
  end
end
