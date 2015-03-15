require 'lotus/utils/string'
require 'lotus/utils/class'

module Lotus
  module Commands
    class Generate
      GENERATORS_NAMESPACE = "Lotus::Generators::%s".freeze

      class Error < ::StandardError
      end

      attr_reader :cli, :source, :target, :app, :app_name, :app_root, :name, :options

      def initialize(type, app_name, name, env, cli)
        @cli      = cli
        @options  = env.to_options.merge(cli.options)

        @app_name = app_name
        @app      = Utils::String.new(@app_name).classify

        @name     = name

        @source = Pathname.new(::File.dirname(__FILE__) + '/../generators/action/').realpath
        @target = Pathname.pwd.realpath

        require "lotus/generators/#{ type }"
        generator  = Utils::String.new(type).classify
        @generator = Utils::Class.load!(GENERATORS_NAMESPACE % generator).new(self)
      end

      def start
        @generator.start
      rescue Error => e
        puts e.message
        exit 1
      end

      def app_root
        @app_root ||= [@options[:path], @app_name].join(::File::SEPARATOR)
      end
    end
  end
end
