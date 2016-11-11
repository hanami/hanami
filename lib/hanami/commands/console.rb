require 'hanami/commands/command'

module Hanami
  module Commands
    # REPL that supports different engines.
    #
    # It is run with:
    #
    #   `bundle exec hanami console`
    #
    # @since 0.1.0
    # @api private
    class Console < Command
      requires 'all'

      # Implements console code reloading
      #
      # @since 0.2.0
      module CodeReloading
        # @since 0.2.0
        def reload!
          puts 'Reloading...'
          Kernel.exec "#{$PROGRAM_NAME} console"
        end
      end

      # Supported engines
      #
      # @since 0.2.0
      # @api private
      ENGINES = {
        'pry'  => 'Pry',
        'ripl' => 'Ripl',
        'irb'  => 'IRB'
      }.freeze

      DEFAULT_ENGINE = ['irb'].freeze

      # @since 0.1.0
      attr_reader :options

      # @param options [Hash] Environment's options
      #
      # @since 0.1.0
      # @see Hanami::Environment#initialize
      def initialize(options)
        super(options)

        @options = @environment.to_options
      end

      # @since 0.1.0
      def start
        prepare
        engine.start
      end

      # @since 0.1.0
      # @api private
      def engine
        load_engine options.fetch(:engine) { engine_lookup }
      end

      private

      # @since 0.9.0
      # @api private
      def prepare
        # Clear out ARGV so Pry/IRB don't attempt to parse the rest
        ARGV.shift until ARGV.empty?

        # Add convenience methods to the main:Object binding
        TOPLEVEL_BINDING.eval('self').__send__(:include, CodeReloading)
      end

      # @since 0.1.0
      # @api private
      def engine_lookup
        (ENGINES.find { |_, klass| Object.const_defined?(klass) } || DEFAULT_ENGINE).first
      end

      # @since 0.1.0
      # @api private
      #
      # rubocop:disable Lint/HandleExceptions
      # rubocop:disable Lint/EnsureReturn
      def load_engine(engine)
        require engine
      rescue LoadError
      ensure
        return Object.const_get(
          ENGINES.fetch(engine) do
            raise ArgumentError.new("Unknown console engine: `#{engine}'")
          end
        )
      end
      # rubocop:enable Lint/EnsureReturn
      # rubocop:enable Lint/HandleExceptions
    end
  end
end
