module Hanami
  module Cli
    module Commands
      # FIXME: this must be a module
      class Destroy
        class Mailer
          include Hanami::Cli::Command
          register "destroy mailer"

          argument :mailer, required: true

          def call(mailer:, **options)
            # TODO: extract this operation into a mixin
            options = Hanami.environment.to_options.merge(options)

            mailer  = Utils::String.new(mailer).underscore.singularize
            context = Context.new(mailer: mailer, options: options)

            assert_valid_mailer!(context)

            destroy_mailer_spec(context)
            destroy_templates(context)
            destroy_mailer(context)

            # FIXME this should be removed
            true
          end

          private

          def assert_valid_mailer!(context)
            # FIXME: extract these hardcoded values
            path = File.join("lib", context.options.fetch(:project), "mailers", "#{context.mailer}.rb")
            return if File.exist?(path)

            path = File.join("lib", context.options.fetch(:project), "mailers")
            warn "cannot find `#{context.mailer}' mailer. Please have a look at `#{path}' directory to find an existing mailer."
            exit(1)
          end

          def destroy_mailer_spec(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.options.fetch(:project), "mailers", "#{context.mailer}_spec.rb")

            FileUtils.rm(destination)

            say(:remove, destination)
          end

          def destroy_templates(context)
            # FIXME: extract these hardcoded values
            pattern      = File.join("lib", context.options.fetch(:project), "mailers", "templates", "#{context.mailer}.*.*")
            destinations = Utils::FileList[pattern]
            destinations.each do |destination|
              FileUtils.rm(destination)

              say(:remove, destination)
            end
          end

          def destroy_mailer(context)
            # FIXME: extract these hardcoded values
            destination = File.join("lib", context.options.fetch(:project), "mailers", "#{context.mailer}.rb")

            FileUtils.rm(destination)

            say(:remove, destination)
          end

          FORMATTER = "%<operation>12s  %<path>s\n".freeze

          def say(operation, path)
            puts(FORMATTER % { operation: operation, path: path })
          end
        end
      end
    end
  end
end
