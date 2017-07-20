module Hanami
  class Cli
    module Commands
      class Console < Command
        # Supported engines
        #
        # @since 0.2.0
        # @api private
        ENGINES = {
          'pry'  => 'Pry',
          'ripl' => 'Ripl',
          'irb'  => 'IRB'
        }.freeze

        requires "all"
        desc 'Starts a hanami console'

        option :environment, desc: 'Path to environment configuration (config/environment.rb)'
        # TODO: OptParser support enums, extract to CLI
        option :engine, desc: "Choose a specific console engine: (#{ENGINES.keys.join('/')})"

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

        # @api private
        DEFAULT_ENGINE = ['irb'].freeze

        # @since 0.1.0
        # @api private
        def call(options)
          context = Context.new(options: options)

          prepare
          engine(context).start
        end

        private

        # @since 0.1.0
        # @api private
        def engine(context)
          load_engine context.options.fetch(:engine) { engine_lookup }
        end

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

    register 'console', Commands::Console
  end
end
