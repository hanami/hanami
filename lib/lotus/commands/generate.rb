require 'lotus/utils/string'
require 'lotus/utils/class'

module Lotus
  module Commands
    class Generate
      GENERATORS_NAMESPACE = "Lotus::Generators::%s".freeze

      class Error < ::StandardError
      end

      attr_reader :cli, :source, :target, :app, :app_name, :name, :options

      def initialize(type, app_name, name, env, cli)
        @cli      = cli
        @options  = env.to_options.merge(cli.options)

        @app_name = app_name
        @app      = Utils::String.new(@app_name).classify

        @name     = name
        @type     = type

        @source   = Pathname.new(::File.dirname(__FILE__) + '/../generators/action/').realpath
        @target   = Pathname.pwd.realpath
      end

      def start
        generator.start
      rescue Error => e
        puts e.message
        exit 1
      end

      def app_root
        @app_root ||= [@options[:path], @app_name].join(::File::SEPARATOR)
      end

      private
      def generator
        require "lotus/generators/#{ @type }"
        class_name = Utils::String.new(@type).classify
        Utils::Class.load!(GENERATORS_NAMESPACE % class_name).new(self)
      end
    end
  end
end
