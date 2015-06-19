# require 'pathname'
# require 'lotus/utils/string'
# require 'lotus/utils/class'

module Lotus
  module Commands
    # @since 0.3.0
    # @api private
    class Generate < Thor
      namespace :generate

      desc 'generate app NAME', 'generate Lotus app (only for Container arch)'
      long_desc <<-DESC
      `lotus generate app admin` will generate a new Lotus application at
      `apps/admin` (`Admin::Application`).

      It will be mounted under the `/admin` URI namespace.

      To customize the path use `--application-base-url=/foo` CLI argument.

      This generator is only available for Container architecture.
DESC

      method_option :application_base_url, desc: 'application base url', type: :string
      method_option :help, aliases: '-h',  desc: 'displays usage'

      def app(name = nil)
        if options[:help] || name.nil?
          invoke :help, ['app']
        else
          require 'lotus/commands/generate/app'
          Lotus::Commands::Generate::App.new(self, environment, name).start
        end
      end

      desc 'generate action [APP] ACTION', 'generate action'
      desc 'action',                       'generate action'
      long_desc <<-DESC
      Generate an action, a view, a template, a route and the relative unit test code.

      View and template generation can be bypassed via `--skip-view=true` CLI argument.

      The route is named after the controller name:

        get '/home', to: 'home#index

      To customize the path use `--path=/` CLI argument.



      The syntax changes according to the current architecture.

      Container:

        `lotus generate action web home#index`

        Generates an action at `apps/web/controllers/home/index.rb`

        The first argument (`web`) is the name of the application.

        The second argument is made of the name of the controller and of the action,
        separated by `#`.



      Application:

        `lotus generate action home#index`

        Generates an action at `app/controllers/home/index.rb`

        The argument is made of the name of the controller and of the action,
        separated by `#`.
DESC

      method_option :path,                     desc: 'relative URI path',                       type: :string
      method_option :skip_view,                desc: 'skip the creation of view and templates', type: :boolean, default: false
      method_option :help,      aliases: '-h', desc: 'displays usage'

      def web_action(app_name = nil, name = nil)
        if options[:help] || name.nil?
          invoke :help, ['action']
        else
          require 'lotus/generators/action'
          Lotus::Generators::Action.new(cli, environment, app_name, name).start
        end
      end

      desc 'generate model', 'generate model'
      desc 'model',          'generate model'

      method_option :help,      aliases: '-h', desc: 'displays usage'

      def model(name = nil)
        if options[:help] || name.nil?
          invoke :help, ['model']
        else
          require 'lotus/commands/generate/model'
          Lotus::Commands::Generate::Model.new(self, environment, name).start
        end
      end

      desc 'generate migration', 'generate migration'
      desc 'migration',          'generate migration'

      method_option :help,      aliases: '-h', desc: 'displays usage'

      def migration(name = nil)
        if options[:help] || name.nil?
          invoke :help, ['migration']
        else
          require 'lotus/commands/generate/migration'
          Lotus::Commands::Generate::Migration.new(self, environment, name).start
        end
      end


#       # @since 0.3.0
#       # @api private
#       GENERATORS_NAMESPACE = "Lotus::Generators::%s".freeze
#       APP_ARCHITECTURE = 'app'.freeze

#       # @since 0.3.0
#       # @api private
#       class Error < ::StandardError
#       end

#       # @since 0.3.0
#       # @api private
#       attr_reader :cli, :source, :target, :app, :app_name, :name, :options, :env

#       # @since 0.3.0
#       # @api private
#       def initialize(type, app_name, name, env, cli)
#         @cli      = cli
#         @env      = env
#         @name     = name
#         @options  = env.to_options.merge(cli.options)

#         sanitize_input(app_name, name)
#         @type     = type

#         @source   = Pathname.new(::File.dirname(__FILE__) + "/../generators/#{ @type }/").realpath
#         @target   = Pathname.pwd.realpath

#         @app      = Utils::String.new(@app_name).classify
#       end

#       # @since 0.3.0
#       # @api private
#       def start
#         generator.start
#       rescue Error => e
#         puts e.message
#         exit 1
#       end

#       # @since 0.3.0
#       # @api private
#       def app_root
#         @app_root ||= begin
#           result = Pathname.new(@options[:apps_path])
#           result = result.join(@app_name) if @env.container?
#           result
#         end
#       end

#       # @since 0.3.0
#       # @api private
#       def spec_root
#         @spec_root ||= Pathname.new('spec')
#       end

#       # @since 0.3.1
#       # @api private
#       def model_root
#         @model_root ||= Pathname.new(['lib', ::File.basename(Dir.getwd)]
#           .join(::File::SEPARATOR))
#       end

#       private
#       # @since 0.3.0
#       # @api private
#       def generator
#         require "lotus/generators/#{ @type }"
#         class_name = Utils::String.new(@type).classify
#         Utils::Class.load!(GENERATORS_NAMESPACE % class_name).new(self)
#       end

#       def sanitize_input(app_name, name)
#         if options[:architecture] == APP_ARCHITECTURE
#           @app_name = nil
#           @name     = app_name
#         else
#           @app_name = app_name
#           @name     = name
#         end
#       end

      private

      def environment
        Lotus::Environment.new(options)
      end
    end
  end
end
