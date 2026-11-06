# frozen_string_literal: true

module Hanami
  # Checks that Hanami's first-party gems are all on the same major.minor version as the `hanami`
  # gem itself.
  #
  # These gems are released together and depend on each other's internals in ways their gemspec
  # constraints cannot fully express. Mixing minor versions (e.g. hanami 3.1 with hanami-view 3.0)
  # can produce subtle, hard-to-diagnose failures, so we check this when `hanami` is required,
  # before it loads any of the other gems.
  #
  # Only gems already activated (i.e. those in the bundle) are checked. Patch versions may differ.
  #
  # Set the `HANAMI_GEM_VERSION_MISMATCH` environment variable to choose what happens on a mismatch:
  #
  # - `warn` (the default) prints a prominent warning to standard error
  # - `raise` raises a {GemVersionMismatchError}, so the app fails to load
  # - `ignore` skips the check
  #
  # @api private
  # @since 3.1.0
  module GemVersionCheck
    # The gems released in lockstep with `hanami`.
    #
    # @api private
    # @since 3.1.0
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

    # @api private
    # @since 3.1.0
    ENV_VAR = "HANAMI_GEM_VERSION_MISMATCH"

    # @api private
    # @since 3.1.0
    BEHAVIOURS = %w[warn raise ignore].freeze

    class << self
      # Runs the check, warning or raising according to the `HANAMI_GEM_VERSION_MISMATCH`
      # environment variable.
      #
      # @param env [#fetch] the environment
      # @param specs [Hash{String => Gem::Specification}] the activated gem specs
      # @param hanami_version [String]
      # @param stderr [IO]
      #
      # @raise [GemVersionMismatchError] if the behaviour is `raise` and versions mismatch
      # @raise [ArgumentError] if the behaviour is unknown
      #
      # @api private
      # @since 3.1.0
      def call(env: ENV, specs: Gem.loaded_specs, hanami_version: Hanami::VERSION, stderr: $stderr)
        behaviour = env.fetch(ENV_VAR, "warn")

        unless BEHAVIOURS.include?(behaviour)
          raise ArgumentError, "#{ENV_VAR} must be one of #{BEHAVIOURS.join(", ")}, got #{behaviour.inspect}"
        end

        return if behaviour == "ignore"

        found = mismatches(specs:, hanami_version:)
        return if found.empty?

        text = message(found, hanami_version:)
        raise GemVersionMismatchError, text if behaviour == "raise"

        # Not `Kernel#warn`, which prints nothing when warnings are disabled (e.g. with `-W0`)
        stderr.puts(banner(text))
      end

      # Returns the activated first-party gems whose major.minor differs from Hanami's.
      #
      # @return [Hash{String => Gem::Version}] gem names mapped to their versions
      #
      # @api private
      # @since 3.1.0
      def mismatches(specs: Gem.loaded_specs, hanami_version: Hanami::VERSION)
        expected = major_minor(Gem::Version.new(hanami_version))

        GEM_NAMES.each_with_object({}) { |name, result|
          spec = specs[name]
          next unless spec
          next if major_minor(spec.version) == expected

          result[name] = spec.version
        }
      end

      private

      def major_minor(version)
        version.segments.first(2)
      end

      def message(found, hanami_version:)
        series = major_minor(Gem::Version.new(hanami_version)).join(".")
        width = found.keys.map(&:length).max

        lines = found.map { |name, version| "  #{name.ljust(width)}  #{version}" }

        <<~MSG
          Hanami gem version mismatch: hanami is #{hanami_version}, but these gems are not on #{series}.x:

          #{lines.join("\n")}

          Hanami's gems are released together and must share the same major.minor version.
          Update your Gemfile so every hanami gem is on #{series}.x, then run `bundle update`.
          To silence this, set #{ENV_VAR}=ignore; to fail instead, set #{ENV_VAR}=raise.
        MSG
      end

      def banner(text)
        rule = "!" * 80
        "\n#{rule}\n#{text.chomp}\n#{rule}\n"
      end
    end
  end
end
