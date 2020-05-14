# frozen_string_literal: true

require "hanami/cli"
require "hanami/cli/application/command"
require "hanami/console/context"

module Hanami
  class CLI
    module Application
      module Commands # rubocop:disable Style/Documentation
        # Hanami application `console` CLI command
        class Console < Command
          REPL =
            begin
              require "pry"
              Pry
            rescue LoadError
              require "irb"
              IRB
            end

          desc "Open interactive console"

          def call(**)
            measure "#{prompt_prefix} booted in" do
              out.puts "=> starting #{prompt_prefix} console"
              application.init
            end

            start_repl
          end

          private

          def start_repl
            context = Hanami::Console::Context.new(application)

            case REPL.name.to_sym
            when :Pry
              start_pry(context)
            when :IRB
              start_irb(context)
            end
          end

          def start_pry(context)
            # https://github.com/pry/pry/pull/1877
            if Gem.loaded_specs["pry"].version >= Gem::Version.new("0.13.0")
              Pry.prompt = Pry::Prompt.new(:hanami, "Hanami Console prompt.", prompt_procs)
              Pry.start(context)
            else
              Pry.start(context, prompt_procs)
            end
          end

          def start_irb(context)
            IRB.start(context, prompt_procs)
          end

          def prompt_procs
            [proc { default_prompt }, proc { indented_prompt }]
          end

          def default_prompt
            "#{prompt_prefix}> "
          end

          def indented_prompt
            "#{prompt_prefix}* "
          end

          def prompt_prefix
            "#{inflector.underscore(application.application_name)}[#{application.config.env}]"
          end
        end

        register "console", Console
      end
    end
  end
end
