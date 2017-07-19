module Hanami
  module Cli
    module Commands
      module Generate
        class Mailer < Command
          requires "environment"
          argument :mailer, required: true
          option :from
          option :to
          option :subject

          def call(mailer:, **options)
            from    = options.fetch(:from,    DEFAULT_FROM)
            to      = options.fetch(:to,      DEFAULT_TO)
            subject = options.fetch(:subject, DEFAULT_SUBJECT)
            context = Context.new(mailer: mailer, test: options.fetch(:test), from: from, to: to, subject: subject, options: options)

            generate_mailer(context)
            generate_mailer_spec(context)
            generate_text_template(context)
            generate_html_template(context)
          end

          private

          DEFAULT_FROM = "'<from>'".freeze

          DEFAULT_TO = "'<to>'".freeze

          DEFAULT_SUBJECT = "'Hello'".freeze

          def generate_mailer(context)
            source      = templates.find("mailer.erb")
            destination = project.mailer(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_mailer_spec(context)
            source      = templates.find("mailer_spec.#{context.test}.erb")
            destination = project.mailer_spec(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_text_template(context)
            destination = project.mailer_template(context, "txt")

            files.touch(destination)
            say(:create, destination)
          end

          def generate_html_template(context)
            destination = project.mailer_template(context, "html")

            files.touch(destination)
            say(:create, destination)
          end
        end
      end
    end
  end
end
