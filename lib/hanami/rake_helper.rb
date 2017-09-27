require 'rake'

module Hanami
  # Install Rake tasks in projects
  #
  # @since 0.6.0
  # @api private
  class RakeHelper
    include Rake::DSL

    # @since 0.6.0
    # @api private
    def self.install_tasks
      new.install
    end

    # @since 0.6.0
    # @api private
    #
    # rubocop:disable Metrics/MethodLength
    def install
      desc "Load the full project"
      task :environment do
        require 'hanami/environment'
        Hanami::Environment.new.require_project_environment
        Components.resolve('all')
      end

      # Ruby ecosystem compatibility
      #
      # Most of the SaaS automatic tasks are designed after Ruby on Rails.
      # They expect the following Rake tasks to be present:
      #
      #   * db:migrate
      #   * assets:precompile
      #
      # See https://github.com/heroku/heroku-buildpack-ruby/issues/442
      #
      # ===
      #
      # These Rake tasks aren't listed when someone runs `rake -T`, because we
      # want to encourage developers to use `hanami` commands.
      #
      # In order to migrate the database or precompile assets a developer should
      # use:
      #
      #   * hanami db migrate
      #   * hanami assets precompile
      #
      # This is the preferred way to run Hanami command line tasks.
      # Please use them when you're in control of your deployment environment.
      #
      # If you're not in control and your deployment requires these "standard"
      # Rake tasks, they are here to solve this only specific problem.
      namespace :db do
        task :migrate do
          run_hanami_command("db migrate")
        end
      end

      namespace :assets do
        task :precompile do
          run_hanami_command("assets precompile")
        end
      end
    end

    private

    # @since 1.1.0
    # @api private
    def run_hanami_command(command)
      require "hanami/cli/commands"
      Hanami::CLI.new(Hanami::CLI::Commands).call(arguments: command.split(/[[:space:]]/))
    end
    # rubocop:enable Metrics/MethodLength
  end
end
