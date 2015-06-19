require 'pathname'
require 'lotus/utils/string'
require 'lotus/utils/class'

module Lotus
  module Commands
    # @since 0.3.0
    # @api private
    class Generate
      # @since 0.3.0
      # @api private
      GENERATORS_NAMESPACE = "Lotus::Generators::%s".freeze
      APP_ARCHITECTURE = 'app'.freeze

      # @since 0.3.0
      # @api private
      class Error < ::StandardError
      end

      # @since 0.3.0
      # @api private
      attr_reader :cli, :source, :target, :app, :app_name, :name, :options, :env

      # @since 0.3.0
      # @api private
      def initialize(type, app_name, name, env, cli)
        @cli      = cli
        @env      = env
        @name     = name
        @options  = env.to_options.merge(cli.options)

        sanitize_input(app_name, name)
        @type     = type

        @source   = Pathname.new(::File.dirname(__FILE__) + "/../generators/#{ @type }/").realpath
        @target   = Pathname.pwd.realpath

        @app      = Utils::String.new(@app_name).classify
      end

      # @since 0.3.0
      # @api private
      def start
        generator.start
      rescue Error => e
        puts e.message
        exit 1
      end

      # @since 0.3.0
      # @api private
      def app_root
        @app_root ||= begin
          result = Pathname.new(@options[:apps_path])
          result = result.join(@app_name) if @env.container?
          result
        end
      end

      # @since 0.3.0
      # @api private
      def spec_root
        @spec_root ||= Pathname.new('spec')
      end

      # @since 0.3.1
      # @api private
      def model_root
        @model_root ||= Pathname.new(['lib', ::File.basename(Dir.getwd)]
          .join(::File::SEPARATOR))
      end

      private
      # @since 0.3.0
      # @api private
      def generator
        require "lotus/generators/#{ @type }.rb"
        class_name = Utils::String.new(@type).classify
        Utils::Class.load!(GENERATORS_NAMESPACE % class_name).new(self)
      end

      def sanitize_input(app_name, name)
        if options[:architecture] == APP_ARCHITECTURE
          @app_name = nil
          @name     = app_name
        else
          @app_name = app_name
          @name     = name
        end
      end
    end
  end
end
