module Lotus
  module Commands
    class Generate
      GENERATORS_NAMESPACE = "Lotus::Generators::%s".freeze

      attr_reader :cli, :source, :target, :app, :app_name, :app_root, :name, :options

      def initialize(type, app_name, name, env, cli)
        @cli      = cli
        @options  = env.to_options

        @app_name = app_name
        @app_root = "apps/#{ @app_name }"
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
      end
    end
  end
end
