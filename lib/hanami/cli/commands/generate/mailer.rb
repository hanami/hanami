module Hanami
  class CLI
    module Commands
      module Generate
        # @since 1.1.0
        # @api private
        class Mailer < Command
          requires "environment"

          desc "Generate a mailer"

          argument :mailer, required: true, desc: "The mailer name (eg. `welcome`)"

          option :from,    desc: "The default `from` field of the mail"
          option :to,      desc: "The default `to` field of the mail"
          option :subject, desc: "The mail subject"

          example [
            "welcome                                         # Basic usage",
            'welcome --from="noreply@example.com"            # Generate with default `from` value',
            'announcement --to="users@example.com"           # Generate with default `to` value',
            'forgot_password --subject="Your password reset" # Generate with default `subject`'
          ]

          # @since 1.1.0
          # @api private
          def call(mailer:, **options)
            from    = clean_option(options.fetch(:from,    DEFAULT_FROM))
            to      = clean_option(options.fetch(:to,      DEFAULT_TO))
            subject = clean_option(options.fetch(:subject, DEFAULT_SUBJECT))
            context = Context.new(mailer: mailer, test: options.fetch(:test), from: from, to: to, subject: subject, options: options)

            generate_mailer(context)
            generate_mailer_spec(context)
            generate_text_template(context)
            generate_html_template(context)
          end

          private

          # @since 1.1.0
          # @api private
          DEFAULT_FROM = "<from>".freeze

          # @since 1.1.0
          # @api private
          DEFAULT_TO = "<to>".freeze

          # @since 1.1.0
          # @api private
          DEFAULT_SUBJECT = "Hello".freeze

          # @since 1.1.1
          # @api private
          QUOTES_REGEX = /^("|')|("|')$/

          # @since 1.1.0
          # @api private
          def generate_mailer(context)
            source      = templates.find("mailer.erb")
            destination = project.mailer(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          # @since 1.1.0
          # @api private
          def generate_mailer_spec(context)
            source      = templates.find("mailer_spec.#{context.test}.erb")
            destination = project.mailer_spec(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          # @since 1.1.0
          # @api private
          def generate_text_template(context)
            destination = project.mailer_template(context, "txt")

            files.touch(destination)
            say(:create, destination)
          end

          # @since 1.1.0
          # @api private
          def generate_html_template(context)
            destination = project.mailer_template(context, "html")

            files.touch(destination)
            say(:create, destination)
          end

          # @since 1.1.1
          # @api private
          def clean_option(option)
            option.gsub(QUOTES_REGEX, '')
          end
        end
      end
    end
  end
end
