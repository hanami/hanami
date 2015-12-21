require 'lotus/routing/route'
require 'lotus/commands/generate/action'
require 'lotus/commands/generate/mailer'

module Lotus
  class CliSubCommands
    # A set of generator subcommands
    #
    # It is run with:
    #
    #   `bundle exec lotus generate`
    #
    # @since x.x.x
    # @api private
    class Generate < Thor
      include Thor::Actions

      namespace :generate

      # @since x.x.x
      # @api private
      desc 'action APPLICATION_NAME CONTROLLER_NAME#ACTION_NAME', 'generate a lotus action'
      long_desc <<-EOS
        `lotus generate action` generates an an action, view and template along with specs and a route.

        For Application architecture the application name is 'app'. For Container architecture the default application is called 'web'.

        > $ lotus generate action app cars#index

        > $ lotus generate action other-app cars#index

        > $ lotus generate action web cars#create --method=post
      EOS
      method_option :method, desc: "The HTTP method to be used for the generated route. Must be one of (#{Lotus::Routing::Route::VALID_HTTP_VERBS.join('/')})", default: Lotus::Commands::Generate::Action::DEFAULT_HTTP_METHOD
      method_option :url, desc: 'Relative URL for action, will be used for the route', default: nil
      method_option :test, desc: 'Defines the testing Framework to be used. Default is defined through your .lotusrc file.'
      method_option :skip_view, desc: 'Skip the generation of the view. Also skips template generation.', default: false, type: :boolean
      method_option :template, desc: 'Extension to be used for the generated template. Default is defined through your .lotusrc file.'
      def actions(application_name, controller_and_action_name)
        if options[:help]
          invoke :help, ['action']
        else
          Lotus::Commands::Generate::Action.new(options, application_name, controller_and_action_name).start
        end
      end

      desc 'migration NAME', 'generate a migration'
      long_desc <<-EOS
      `lotus generate migration` will generate an empty migration file.

      > $ lotus generate migration do_something
      EOS
      def migration(name)
        if options[:help]
          invoke :help, ['migration']
        else
          require 'lotus/commands/generate/migration'
          Lotus::Commands::Generate::Migration.new(options, name).start
        end
      end

      desc 'model NAME', 'generate an entity'
      long_desc <<-EOS
        `lotus generate model` will generate an entity along with repository
        and corresponding tests. The name of the model can contain slashes to
        indicate module names.

        > $ lotus generate model car

        > $ lotus generate model car --attributes=brand,model

        > $ lotus generate model vehicles/car
      EOS
      method_option :attributes, desc: 'Defines attributes for the generated model'
      method_option :test, desc: 'Defines the testing Framework to be used. Default is defined through your .lotusrc file.'
      def model(name)
        if options[:help]
          invoke :help, ['model']
        else
          require 'lotus/commands/generate/model'
          Lotus::Commands::Generate::Model.new(options, name).start
        end
      end

      desc 'mailer NAME', 'generate a mailer'
      long_desc <<-EOS
      `lotus generate mailer` will generate an empty mailer, along with templates and specs.

      > $ lotus generate mailer forgot_password
      > $ lotus generate mailer forgot_password --to "'log@bookshelf.com'" --from "'support@bookshelf.com'" --subject "'New Password'"
      EOS
      method_option :to, desc: 'sender email', default: Lotus::Commands::Generate::Mailer::DEFAULT_TO
      method_option :from, desc: 'sendee email', default: Lotus::Commands::Generate::Mailer::DEFAULT_FROM
      method_option :subject, desc: 'email subject', default: Lotus::Commands::Generate::Mailer::DEFAULT_SUBJECT
      def mailer(name)
        if options[:help]
          invoke :help, ['mailer']
        else
          Lotus::Commands::Generate::Mailer.new(options, name).start
        end
      end

      desc 'app APPLICATION_NAME', 'generate an app'
      long_desc <<-EOS
        `lotus generate app` creates a new app inside the 'apps' directory.

        It can only be called for lotus applications with container architecture.

        > $ lotus generate app admin

        > $ lotus generate app reporting --application_base_url=/reports
      EOS
      method_option :application_base_url, desc: 'Base URL for the new app. If missing, then it is inferred from APPLICATION_NAME'
      def app(application_name)
        if options[:help]
          invoke :help, ['app']
        else
          require 'lotus/commands/generate/app'
          Lotus::Commands::Generate::App.new(options, application_name).start
        end
      end
    end
  end
end
