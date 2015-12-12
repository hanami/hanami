require 'lotus/routing/route'
require 'lotus/cli_sub_commands/base'
require 'lotus/commands/generate/action'

module Lotus
  class CliSubCommands
    class Destroy < Base
      namespace :destroy

      desc 'action APPLICATION_NAME CONTROLLER_NAME#ACTION_NAME', 'destroy a lotus action'
      long_desc <<-EOS
        `lotus destroy action` will destroy an an action, view and template along with specs and a route.

        For Application architecture the application name is 'app'. For Container architecture the default application is called 'web'.

        > $ lotus destroy action app cars#index

        > $ lotus destroy action other-app cars#index

        > $ lotus destroy action web cars#create --method=post
      EOS

      method_option :method, desc: "The HTTP method used when the route was generated. Must be one of (#{Lotus::Routing::Route::VALID_HTTP_VERBS.join('/')})", default: Lotus::Commands::Generate::Action::DEFAULT_HTTP_METHOD
      method_option :url, desc: 'Relative URL for action, will be used for the route', default: nil
      method_option :template, desc: 'Extension used when the template was generated. Default is defined through your .lotusrc file.'

      def actions(application_name, controller_and_action_name)
        invoke_help_action_or('action') do
          Lotus::Commands::Generate::Action.new(options, application_name, controller_and_action_name).destroy.start
        end
      end

      desc 'migration NAME', 'destroy a migration'
      long_desc <<-EOS
      `lotus destroy migration` will destroy a migration file.

      > $ lotus destroy migration create_books
      EOS

      def migration(name)
        invoke_help_action_or('migration') do
          require 'lotus/commands/generate/migration'
          Lotus::Commands::Generate::Migration.new(options, name).destroy.start
        end
      end

      desc 'model NAME', 'destroy an entity'
      long_desc <<-EOS
        `lotus destroy model` will destroy an entity along with repository
        and corresponding tests

        > $ lotus generate model car
      EOS

      def model(name)
        invoke_help_action_or('model') do
          require 'lotus/commands/generate/model'
          Lotus::Commands::Generate::Model.new(options, name).destroy.start
        end
      end

      desc 'application NAME', 'destroy an application'
      long_desc <<-EOS
      `lotus destroy application` will destroy an application, along with templates and specs.

      > $ lotus destroy application api
      EOS
      def application(name)
        invoke_help_action_or('app') do
          require 'lotus/commands/generate/app'
          Lotus::Commands::Generate::App.new(options, name).destroy.start
        end
      end

      desc 'mailer NAME', 'destroy a mailer'
      long_desc <<-EOS
      `lotus destroy mailer` will destroy a mailer, along with templates and specs.

      > $ lotus destroy mailer forgot_password
      EOS

      def mailer(name)
        invoke_help_action_or('mailer') do
          require 'lotus/commands/generate/mailer'

          options[:behavior] = :revoke
          Lotus::Commands::Generate::Mailer.new(options, name).destroy.start
        end
      end
    end
  end
end
