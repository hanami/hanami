# frozen_string_literal: true

module Hanami
  module Providers
    # Registers the `"mailers.delivery_method"` component. This is an SMTP delivery method built
    # from SMTP environment variables when present, otherwise the test delivery method.
    #
    # SMTP env vars may take a per-slice prefix derived from the slice name (e.g. an "admin" slice
    # reads `ADMIN__SMTP_ADDRESS`, falling back to `SMTP_ADDRESS`). Register your own `:mailers`
    # provider if you need to use another delivery method or different setup logic.
    #
    # @api private
    class Mailers < Hanami::Provider::Source
      # Maps SMTP environment variable names to their compatible delivery option keys.
      #
      # Example values:
      #
      #   SMTP_ADDRESS=smtp.example.com
      #   SMTP_PORT=587
      #   SMTP_USERNAME=postmaster@example.com
      #   SMTP_PASSWORD=s3cr3t
      #   SMTP_AUTHENTICATION=plain
      SMTP_ENV_VARS = {
        "SMTP_ADDRESS" => :address,
        "SMTP_PORT" => :port,
        "SMTP_USERNAME" => :user_name,
        "SMTP_PASSWORD" => :password,
        "SMTP_AUTHENTICATION" => :authentication
      }.freeze

      # Coercions applied to SMTP env var values, keyed by option. Options not listed here are
      # passed through unchanged (as strings).
      SMTP_COERCIONS = Hash.new(:itself.to_proc).update(
        port: ->(value) { Integer(value) },
        authentication: ->(value) { value.to_sym }
      ).freeze

      def start
        require "hanami/mailer"

        register "delivery_method", build_delivery_method
      end

      private

      # Builds an SMTP delivery method when SMTP env vars are present; otherwise the test
      # delivery method. In production with no SMTP configuration, warns noisily before falling
      # back to the test delivery method (mail will not be sent) — but never raises, so an app
      # whose mail setup is still a work in progress can boot.
      def build_delivery_method
        smtp_options = smtp_options_from_env

        return Hanami::Mailer::Delivery::SMTP.new(**smtp_options) if smtp_options.key?(:address)

        warn_missing_smtp if Hanami.env?(:production)

        Hanami::Mailer::Delivery::Test.new
      end

      def smtp_options_from_env
        SMTP_ENV_VARS.each_with_object({}) do |(var, option), options|
          value = env_value(var)
          next if value.nil?

          coercion = SMTP_COERCIONS[option]
          options[option] = coercion ? coercion.call(value) : value
        end
      end

      # Reads an SMTP env var, preferring a per-slice prefixed name (e.g. `ADMIN__SMTP_ADDRESS`)
      # and falling back to the unprefixed name shared across slices.
      def env_value(var)
        return ENV[var] if slice.app?

        slice_prefixed_var = "#{slice.slice_name.name.gsub("/", "__").upcase}__#{var}"
        ENV[slice_prefixed_var] || ENV[var]
      end

      def warn_missing_smtp
        message = \
          "No SMTP configuration found for #{slice.slice_name.name} in production; " \
          "falling back to the test delivery method — mail will NOT be sent. " \
          "Set SMTP_ADDRESS (and related SMTP_* variables), or register a custom :mailers provider."

        slice.app["logger"].warn(message)
      end
    end

    Dry::System.register_provider_source(
      :mailers,
      source: Mailers,
      group: :hanami,
      provider_options: {namespace: true}
    )
  end
end
