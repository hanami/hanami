require 'lotus/generators/abstract'
require 'lotus/utils/string'

module Lotus
  module Generators
    # @since 0.5.0
    # @api private
    class Mailer < Abstract

      # @since 0.5.0
      # @api private
      TXT_FORMAT  = '.txt'.freeze

      # @since 0.5.0
      # @api private
      HTML_FORMAT  = '.html'.freeze

      # @since 0.5.0
      # @api private
      DEFAULT_ENGINE = 'erb'.freeze

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
      def initialize(command)
        super

        @mailer_name = Utils::String.new(name).classify
        cli.class.source_root(source)
      end

      # @since 0.5.0
      # @api private
      def start
        assert_mailer!

        opts = {
          mailer:  @mailer_name,
          from:    DEFAULT_FROM,
          to:      DEFAULT_TO,
          subject: DEFAULT_SUBJECT,
        }

        templates = {
          'mailer_spec.rb.tt' => _mailer_spec_path,
          'mailer.rb.tt'      => _mailer_path,
          'template.txt.tt'   => _txt_template_path,
          'template.html.tt'  => _html_template_path,
        }

        templates.each do |src, dst|
          cli.template(source.join(src), target.join(dst), opts)
        end
      end

      # @since 0.5.0
      # @api private
      def assert_mailer!
        if @mailer_name.nil? || @mailer_name.empty?
          raise Lotus::Commands::Generate::Error.new("Missing mailer name")
        end
      end

      # @since 0.5.0
      # @api private
      def _mailer_path
        core_root.join('mailers', "#{ name }.rb").to_s
      end

      # @since 0.5.0
      # @api private
      def _mailer_spec_path
        spec_root.join(::File.basename(Dir.getwd), 'mailers', "#{ name }_spec.rb")
      end

      # @since 0.5.0
      # @api private
      def _txt_template_path
        __template_path(TXT_FORMAT)
      end

      # @since 0.5.0
      # @api private
      def _html_template_path
        __template_path(HTML_FORMAT)
      end

      # @since 0.5.0
      # @api private
      def __template_path(format)
        core_root.join('mailers', 'templates', "#{ name }#{ format }.#{ DEFAULT_ENGINE }")
      end

      # @since 0.5.0
      # @api private
      def name
        Utils::String.new(app_name || super).underscore
      end
    end
  end
end
