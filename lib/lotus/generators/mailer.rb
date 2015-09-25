require 'lotus/generators/abstract'
require 'lotus/utils/string'

module Lotus
  module Generators
    # @since 0.3.0
    # @api private
    class Mailer < Abstract

      # @since 0.3.0
      # @api private
      TEMPLATE_SUFFIX  = '.txt.'.freeze

      # @since 0.3.0
      # @api private
      DEFAULT_TEMPLATE = 'erb'.freeze

      # @since 0.3.0
      # @api private
      def initialize(command)
        super

        @mailer_name = Utils::String.new(name).classify
        cli.class.source_root(source)
      end

      # @since 0.3.0
      # @api private
      def start
        assert_mailer!

        opts = {
          mailer: @mailer_name,
        }

        templates = {
          'mailer_spec.rb.tt' => _mailer_spec_path,
          'mailer.rb.tt' => _mailer_path,
          'template.tt' => _template_path
        }

        templates.each do |src, dst|
          cli.template(source.join(src), target.join(dst), opts)
        end
      end


      # @since 0.3.2
      # @api private
      def assert_mailer!
        if @mailer_name.nil?
          raise Lotus::Commands::Generate::Error.new("Missing mailer name")
        end
      end


      # @since 0.3.0
      # @api private
      def _mailer_path
        model_root.join("#{ name }.rb").to_s
      end

      # @since 0.3.0
      # @api private
      def _mailer_spec_path
        spec_root.join(::File.basename(Dir.getwd), 'mailers', "#{ name }_spec.rb")
      end

      # @since 0.5.0
      # @api private
      def _template_path
        model_root.join("mailers/templates", "#{ name }#{ TEMPLATE_SUFFIX }#{ DEFAULT_TEMPLATE }")
      end

      # @since 0.4.0
      # @api private
      def name
        Utils::String.new(app_name || super).underscore
      end

    end
  end
end
