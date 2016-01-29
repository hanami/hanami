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
    class Console
      module Methods
        def reload!
          puts 'Reloading...'
          Kernel.exec "#{$0} console"
        end
      end

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
        @environment = Hanami::Environment.new(options)
        @options     = @environment.to_options
      end

      # @since 0.1.0
      def start
        # Clear out ARGV so Pry/IRB don't attempt to parse the rest
        ARGV.shift until ARGV.empty?
        @environment.require_application_environment

        # Add convenience methods to the main:Object binding
        TOPLEVEL_BINDING.eval('self').send(:include, Methods)

        load_application
        engine.start
      end

      # @since 0.1.0
      # @api private
      def engine
        load_engine options.fetch(:engine) { engine_lookup }
      end

      private

      # @since 0.1.0
      # @api private
      def engine_lookup
        (ENGINES.find { |_, klass| Object.const_defined?(klass) } || DEFAULT_ENGINE).first
      end

      # @since 0.1.0
      # @api private
      def load_engine(engine)
        require engine
      rescue LoadError
      ensure
        return Object.const_get(
          ENGINES.fetch(engine) {
            raise ArgumentError.new("Unknown console engine: #{ engine }")
          }
        )
      end

      # @since 0.1.0
      # @api private
      def load_application
        if @environment.container?
          Hanami::Container.new
        else
          Hanami::Application.preload_applications!
        end
      end
    end
  end
end
