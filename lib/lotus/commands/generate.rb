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

      # @since 0.3.0
      # @api private
      class Error < ::StandardError
      end

      # @since 0.3.0
      # @api private
      attr_reader :cli, :source, :target, :app, :app_name, :name, :options, :resource, :env

      # @since 0.3.0
      # @api private
      def initialize(type, app_name, name, env, cli, resource = nil)
        @cli      = cli
        @options  = env.to_options.merge(cli.options)

        @app_name = app_name
        @app      = Utils::String.new(@app_name).classify

        @name     = name
        @type     = type

        @source   = Pathname.new(::File.dirname(__FILE__) + "/../generators/#{ @type }/").realpath
        @target   = Pathname.pwd.realpath

        @env = env
        @resource = resource
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
        @app_root ||= Pathname.new([@options[:path], @app_name].join(::File::SEPARATOR))
      end

      # @since 0.3.0
      # @api private
      def spec_root
        @spec_root ||= Pathname.new('spec')
      end

      def model_root
        @model_root ||= Pathname.new(['lib', target.to_s.split(::File::SEPARATOR).last]
          .join(::File::SEPARATOR))
      end

      private
      # @since 0.3.0
      # @api private
      def generator
        require "lotus/generators/#{ @type }"
        class_name = Utils::String.new(@type).classify
        Utils::Class.load!(GENERATORS_NAMESPACE % class_name).new(self)
      end
    end
  end
end
