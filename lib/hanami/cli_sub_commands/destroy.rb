require 'hanami/routing/route'
require 'hanami/commands/generate/action'

module Hanami
  class CliSubCommands
    # @api private
    class Destroy < Thor
      extend CliBase
      include Thor::Actions
      namespace :destroy

      desc 'action APPLICATION_NAME CONTROLLER_NAME#ACTION_NAME', 'Destroy a hanami action'
      long_desc <<-EOS
        `hanami destroy action` will destroy an an action, view and template along with specs and a route.

        For Application architecture the application name is 'app'. For Container architecture the default application is called 'web'.

        > $ hanami destroy action app cars#index

        > $ hanami destroy action other-app cars#index

        > $ hanami destroy action web cars#create --method=post
      EOS

      method_option :method, desc: "The HTTP method used when the route was generated. Must be one of (#{Hanami::Routing::Route::VALID_HTTP_VERBS.join('/')})", default: Hanami::Commands::Generate::Action::DEFAULT_HTTP_METHOD
      method_option :url, desc: 'Relative URL for action, will be used for the route', default: nil
      method_option :template, desc: 'Extension used when the template was generated. Default is defined through your .hanamirc file.'

      # @api private
      def actions(application_name = nil, controller_and_action_name)
        if Hanami::Environment.new(options).container? && application_name.nil?
          msg = "ERROR: \"hanami destroy action\" was called with arguments [\"#{controller_and_action_name}\"]\n" \
                "Usage: \"hanami destroy action APPLICATION_NAME CONTROLLER_NAME#ACTION_NAME\""
          fail Error, msg
        end

        if options[:help]
          invoke :help, ['action']
        else
          Hanami::Commands::Generate::Action.new(options, application_name, controller_and_action_name).destroy.start
        end
      end

      desc 'migration NAME', 'Destroy a migration'
      long_desc <<-EOS
      `hanami destroy migration` will destroy a migration file.

      > $ hanami destroy migration create_books
      EOS

      # @api private
      def migration(name)
        if options[:help]
          invoke :help, ['migration']
        else
          require 'hanami/commands/generate/migration'
          Hanami::Commands::Generate::Migration.new(options, name).destroy.start
        end
      end

      desc 'model NAME', 'Destroy an entity'
      long_desc <<-EOS
        `hanami destroy model` will destroy an entity along with repository
        and corresponding tests

        > $ hanami destroy model car
      EOS

      # @api private
      def model(name)
        if options[:help]
          invoke :help, ['model']
        else
          require 'hanami/commands/generate/model'
          Hanami::Commands::Generate::Model.new(options, name).destroy.start
        end
      end

      desc 'application NAME', 'Destroy an application'
      long_desc <<-EOS
      `hanami destroy application` will destroy an application, along with templates and specs.

      > $ hanami destroy application api
      EOS
      # @api private
      def application(name)
        if options[:help]
          invoke :help, ['app']
        else
          require 'hanami/commands/generate/app'
          Hanami::Commands::Generate::App.new(options, name).destroy.start
        end
      end

      desc 'mailer NAME', 'Destroy a mailer'
      long_desc <<-EOS
      `hanami destroy mailer` will destroy a mailer, along with templates and specs.

      > $ hanami destroy mailer forgot_password
      EOS

      # @api private
      def mailer(name)
        if options[:help]
          invoke :help, ['mailer']
        else
          require 'hanami/commands/generate/mailer'

          options[:behavior] = :revoke
          Hanami::Commands::Generate::Mailer.new(options, name).destroy.start
        end
      end
    end
  end
end
