module Hanami
  class CLI
    module Commands
      # @since 1.1.0
      # @api private
      class Console < Command
        # Supported engines
        #
        # @since 1.1.0
        # @api private
        ENGINES = {
          'pry'  => 'Pry',
          'ripl' => 'Ripl',
          'irb'  => 'IRB'
        }.freeze

        requires "all"
        desc "Starts Hanami console"

        # TODO: OptParser support enums, extract to CLI
        option :engine, desc: "Force a specific console engine: (#{ENGINES.keys.join('/')})"

        example [
          "             # Uses the bundled engine",
          "--engine=pry # Force to use Pry"
        ]

        # Implements console code reloading
        #
        # @since 1.1.0
        # @api private
        module CodeReloading
          # @since 1.1.0
          # @api private
          def reload!
            puts 'Reloading...'
            Kernel.exec "#{$PROGRAM_NAME} console"
          end
        end

        # @since 1.1.0
        # @api private
        DEFAULT_ENGINE = ['irb'].freeze

        # @since 1.1.0
        # @api private
        def call(options)
          context = Context.new(options: options)

          prepare
          engine(context).start
        end

        private

        # @since 1.1.0
        # @api private
        def engine(context)
          load_engine context.options.fetch(:engine) { engine_lookup }
        end

        # @since 1.1.0
        # @api private
        def prepare
          # Clear out ARGV so Pry/IRB don't attempt to parse the rest
          ARGV.shift until ARGV.empty?

          # Add convenience methods to the main:Object binding
          TOPLEVEL_BINDING.eval('self').__send__(:include, CodeReloading)
        end

        # @since 1.1.0
        # @api private
        def engine_lookup
          (ENGINES.find { |_, klass| Object.const_defined?(klass) } || DEFAULT_ENGINE).first
        end

        # @since 1.1.0
        # @api private
        def load_engine(engine)
          require engine
          Object.const_get(ENGINES.fetch(engine))
        rescue LoadError, NameError
          if ENGINES.key?(engine) # rubocop:disable Style/GuardClause
            raise ArgumentError.new("Missing gem for `#{engine}' console engine. Please make sure to add it to `Gemfile'.")
          else
            raise ArgumentError.new("Unknown console engine: `#{engine}'.")
          end
        end
      end
    end

    register "console", Commands::Console, aliases: ["c"]
  end
end
