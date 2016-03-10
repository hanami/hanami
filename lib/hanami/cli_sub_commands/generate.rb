require 'hanami/routing/route'
require 'hanami/commands/generate/action'
require 'hanami/commands/generate/mailer'

module Hanami
  class CliSubCommands
    # A set of generator subcommands
    #
    # It is run with:
    #
    #   `bundle exec hanami generate`
    #
    # @since 0.6.0
    # @api private
    class Generate < Thor
      include Thor::Actions

      namespace :generate

      # @since 0.6.0
      # @api private
      desc 'action APPLICATION_NAME CONTROLLER_NAME#ACTION_NAME', 'Generate a hanami action'
      long_desc <<-EOS
        `hanami generate action` generates an an action, view and template along with specs and a route.

        For Application architecture the application name is 'app'. For Container architecture the default application is called 'web'.

        > $ hanami generate action app cars#index

        > $ hanami generate action other-app cars#index

        > $ hanami generate action web cars#create --method=post
      EOS
      method_option :method, desc: "The HTTP method to be used for the generated route. Default is #{Hanami::Commands::Generate::Action::DEFAULT_HTTP_METHOD}. Must be one of (#{Hanami::Routing::Route::VALID_HTTP_VERBS.join('/')})"
      method_option :url, desc: 'Relative URL for action, will be used for the route', default: nil
      method_option :test, desc: 'Defines the testing Framework to be used. Default is defined through your .hanamirc file.'
      method_option :skip_view, desc: 'Skip the generation of the view. Also skips template generation.', default: false, type: :boolean
      method_option :template, desc: 'Extension to be used for the generated template. Default is defined through your .hanamirc file.'
      def actions(application_name = nil, controller_and_action_name)
        if Hanami::Environment.new(options).container? && application_name.nil?
          msg = "ERROR: \"hanami generate action\" was called with arguments [\"#{controller_and_action_name}\"]\n" \
                "Usage: \"hanami action APPLICATION_NAME CONTROLLER_NAME#ACTION_NAME\""
          fail Error, msg
        end

        if options[:help]
          invoke :help, ['action']
        else
          Hanami::Commands::Generate::Action.new(options, application_name, controller_and_action_name).start
        end
      end

      desc 'migration NAME', 'Generate a migration'
      long_desc <<-EOS
      `hanami generate migration` will generate an empty migration file.

      > $ hanami generate migration do_something
      EOS
      def migration(name)
        if options[:help]
          invoke :help, ['migration']
        else
          require 'hanami/commands/generate/migration'
          Hanami::Commands::Generate::Migration.new(options, name).start
        end
      end

      desc 'model NAME', 'Generate an entity'
      long_desc <<-EOS
        `hanami generate model` will generate an entity along with repository
        and corresponding tests. The name of the model can contain slashes to
        indicate module names.

        > $ hanami generate model car

        > $ hanami generate model vehicles/car
      EOS
      method_option :test, desc: 'Defines the testing Framework to be used. Default is defined through your .hanamirc file.'
      def model(name)
        if options[:help]
          invoke :help, ['model']
        else
          require 'hanami/commands/generate/model'
          Hanami::Commands::Generate::Model.new(options, name).start
        end
      end

      desc 'mailer NAME', 'Generate a mailer'
      long_desc <<-EOS
      `hanami generate mailer` will generate an empty mailer, along with templates and specs.

      > $ hanami generate mailer forgot_password
      > $ hanami generate mailer forgot_password --to "'log@bookshelf.com'" --from "'support@bookshelf.com'" --subject "'New Password'"
      EOS
      method_option :to, desc: 'Sender email', default: Hanami::Commands::Generate::Mailer::DEFAULT_TO
      method_option :from, desc: 'Sendee email', default: Hanami::Commands::Generate::Mailer::DEFAULT_FROM
      method_option :subject, desc: 'Email subject', default: Hanami::Commands::Generate::Mailer::DEFAULT_SUBJECT
      def mailer(name)
        if options[:help]
          invoke :help, ['mailer']
        else
          Hanami::Commands::Generate::Mailer.new(options, name).start
        end
      end

      desc 'app APPLICATION_NAME', 'Generate an app'
      long_desc <<-EOS
        `hanami generate app` creates a new app inside the 'apps' directory.

        It can only be called for hanami applications with container architecture.

        > $ hanami generate app admin

        > $ hanami generate app reporting --application_base_url=/reports
      EOS
      method_option :application_base_url, desc: 'Base URL for the new app. If missing, then it is inferred from APPLICATION_NAME'
      def app(application_name)
        if options[:help]
          invoke :help, ['app']
        else
          require 'hanami/commands/generate/app'
          Hanami::Commands::Generate::App.new(options, application_name).start
        end
      end
    end
  end
end
