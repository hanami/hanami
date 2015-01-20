require 'pathname'
require 'lotus/utils/string'
require 'lotus/utils/class'

module Lotus
  module Commands
    class New
      GENERATORS_NAMESPACE = "Lotus::Generators::Application::%s".freeze

      attr_reader :app_name, :source, :target, :cli, :options

      def initialize(app_name, environment, cli)
        @app_name = _get_real_app_name(app_name)
        @options  = environment.to_options
        @arch     = @options.fetch(:architecture)

        @target   = Pathname.pwd.join(@options.fetch(:path, app_name))
        @source   = Pathname.new(@options.fetch(:source) { ::File.dirname(__FILE__) + '/../generators/application/' }).join(@arch)

        @cli      = cli

        require "lotus/generators/application/#{ @arch }"
        command  = Utils::String.new(@arch).classify
        @command = Utils::Class.load!(GENERATORS_NAMESPACE % command).new(self)
      end

      def start
        @command.start
      end

      private
      def _get_real_app_name(app_name)
        if app_name.include?(::File::SEPARATOR)
          raise ArgumentError.new("Invalid application name. If you want to set application path, please use --path option")
        end

        app_name == '.' ? ::File.basename(Dir.getwd) : app_name
      end
    end
  end
end
