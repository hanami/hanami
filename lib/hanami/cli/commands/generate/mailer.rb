module Hanami
  module Cli
    module Commands
      module Generate
        class Mailer < Command
          argument :mailer, required: true
          option :from
          option :to
          option :subject

          def call(mailer:, **options)
            # TODO: extract this operation into a mixin
            options = Hanami.environment.to_options.merge(options)

            from    = options.fetch(:from,    DEFAULT_FROM)
            to      = options.fetch(:to,      DEFAULT_TO)
            subject = options.fetch(:subject, DEFAULT_SUBJECT)
            context = Context.new(mailer: mailer, test: options.fetch(:test), from: from, to: to, subject: subject, options: options)

            generate_mailer(context)
            generate_mailer_spec(context)
            generate_text_template(context)
            generate_html_template(context)

            true
          end

          private

          DEFAULT_FROM = "'<from>'".freeze

          DEFAULT_TO = "'<to>'".freeze

          DEFAULT_SUBJECT = "'Hello'".freeze

          def generate_mailer(context)
            # FIXME: extract these hardcoded values
            destination = File.join("lib", context.options.fetch(:project), "mailers", "#{context.mailer}.rb")
            source      = File.join(__dir__, "mailer", "mailer.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_mailer_spec(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.options.fetch(:project), "mailers", "#{context.mailer}_spec.rb")
            source      = File.join(__dir__, "mailer", "mailer_spec.#{context.test}.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_text_template(context)
            # FIXME: extract these hardcoded values
            destination = File.join("lib", context.options.fetch(:project), "mailers", "templates", "#{context.mailer}.txt.#{context.options.fetch(:template)}")

            files.touch(destination)
            say(:create, destination)
          end

          def generate_html_template(context)
            # FIXME: extract these hardcoded values
            destination = File.join("lib", context.options.fetch(:project), "mailers", "templates", "#{context.mailer}.html.#{context.options.fetch(:template)}")

            files.touch(destination)
            say(:create, destination)
          end
        end
      end
    end
  end
end
