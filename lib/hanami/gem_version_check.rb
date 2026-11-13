# frozen_string_literal: true

module Hanami
  # Checks that Hanami's first-party gems are all on the same major.minor version as the `hanami`
  # gem itself. Patch versions may differ.
  #
  # These gems are released together and depend on each other's internals in ways their gemspec
  # constraints cannot fully express. Mixing minor versions (e.g. hanami 3.1 with hanami-view 3.0)
  # can produce subtle, hard-to-diagnose failures, so we check this when `hanami` is required,
  # before it loads any of the other gems, and raise a {GemVersionMismatchError} on a mismatch.
  #
  # Only gems already activated (i.e. those in the bundle) are checked. Without Bundler, gems
  # activated later (e.g. via {Hanami.bundled?}) are not checked.
  #
  # Set the `HANAMI_SKIP_GEM_VERSION_CHECK` environment variable (to any value) to skip the check.
  #
  # @api private
  module GemVersionCheck
    # The gems released in lockstep with `hanami`.
    GEM_NAMES = %w[
      hanami-action
      hanami-assets
      hanami-cli
      hanami-db
      hanami-mailer
      hanami-minitest
      hanami-reloader
      hanami-router
      hanami-rspec
      hanami-utils
      hanami-view
      hanami-webconsole
    ].freeze

    SKIP_ENV_VAR = "HANAMI_SKIP_GEM_VERSION_CHECK"

    class << self
      # Runs the check, unless the `HANAMI_SKIP_GEM_VERSION_CHECK` environment variable is set.
      #
      # @param env [#key?] the environment
      # @param specs [Hash{String => Gem::Specification}] the activated gem specs
      # @param hanami_version [String]
      #
      # @raise [GemVersionMismatchError] if any first-party gem's major.minor differs from Hanami's
      def call(env: ENV, specs: Gem.loaded_specs, hanami_version: Hanami::VERSION)
        return if env.key?(SKIP_ENV_VAR)

        series = major_minor(hanami_version)
        mismatched = specs.slice(*GEM_NAMES)
          .transform_values(&:version)
          .reject { |_, version| major_minor(version) == series }
        return if mismatched.empty?

        raise GemVersionMismatchError, message(mismatched, hanami_version:, series: series.join("."))
      end

      private

      def major_minor(version)
        Gem::Version.new(version).segments.first(2)
      end

      def message(mismatched, hanami_version:, series:)
        lines = mismatched.map { |name, version| "  #{name} #{version}" }

        <<~MSG
          hanami is #{hanami_version}, but these gems are not on #{series}.x:

          #{lines.join("\n")}

          Hanami's gems are released together and must share the same major.minor version.
          Update your Gemfile so every hanami gem is on #{series}.x, then run `bundle update`.
          To skip this check, set #{SKIP_ENV_VAR}=1.
        MSG
      end
    end
  end
end
