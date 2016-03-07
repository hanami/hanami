require "hanami/commands/generate/abstract"

module Hanami
  module Commands
    class Generate
      # @since 0.5.0
      # @api private
      class Mailer < Abstract

        attr_reader :name, :name_underscored, :from, :to, :subject

        # @since 0.5.0
        # @api private
        TXT_FORMAT  = ".txt".freeze

        # @since 0.5.0
        # @api private
        HTML_FORMAT  = ".html".freeze

        # @since 0.5.0
        # @api private
        DEFAULT_ENGINE = "erb".freeze

        # @since 0.5.0
        # @api private
        DEFAULT_FROM = "'<from>'".freeze

        # @since 0.5.0
        # @api private
        DEFAULT_TO = "'<to>'".freeze

        # @since 0.5.0
        # @api private
        DEFAULT_SUBJECT = "'Hello'".freeze

        # @since 0.5.0
        # @api private
        def initialize(options, name)
          super(options)

          @name_underscored = Utils::String.new(name).underscore
          @name             = Utils::String.new(name_underscored).classify
          @from             = options[:from] || DEFAULT_FROM
          @to               = options[:to] || DEFAULT_TO
          @subject          = options[:subject] || DEFAULT_SUBJECT

          assert_name!
        end

        # @since 0.x.x
        # @api private
        def map_templates
          add_mapping("mailer_spec.rb.tt", mailer_spec_path)
          add_mapping("mailer.rb.tt", mailer_path)
          add_mapping("template.txt.tt", txt_template_path)
          add_mapping("template.html.tt", html_template_path)
        end

        def template_options
          {
            mailer:  name,
            from:    from,
            to:      to,
            subject: subject,
          }
        end

        private

        # @since 0.5.0
        # @api private
        def assert_name!
          if argument_blank?(name)
            raise ArgumentError.new('Mailer name is missing')
          end
        end

        # @since 0.5.0
        # @api private
        def mailer_path
          core_root.join('mailers', "#{ name_underscored }.rb").to_s
        end

        # @since 0.5.0
        # @api private
        def mailer_spec_path
          spec_root.join(::File.basename(Dir.getwd), "mailers", "#{ name_underscored }_spec.rb")
        end

        # @since 0.5.0
        # @api private
        def txt_template_path
          template_path(TXT_FORMAT)
        end

        # @since 0.5.0
        # @api private
        def html_template_path
          template_path(HTML_FORMAT)
        end

        # @since 0.5.0
        # @api private
        def template_path(format)
          core_root.join("mailers", "templates", "#{ name_underscored }#{ format }.#{ DEFAULT_ENGINE }")
        end

        def spec_root
          Pathname.new("spec")
        end

        def core_root
          Pathname.new("lib").join(::File.basename(Dir.getwd))
        end
      end
    end
  end
end
