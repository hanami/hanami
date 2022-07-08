# frozen_string_literal: true

require "hanami/cli/rake_tasks"
require "hanami/cli/command_line"

Hanami::CLI::RakeTasks.register_tasks do
  @_hanami_command_line = Hanami::CLI::CommandLine.new

  desc "Load the app environment"
  task :environment do
    require "hanami/prepare"
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
      # TODO(@jodosha): Enable when we'll integrate with ROM
      # run_hanami_command("db migrate")
    end
  end

  namespace :assets do
    task :precompile do
      # TODO(@jodosha): Enable when we'll integrate with hanami-assets
      # run_hanami_command("assets precompile")
    end
  end

  private

  def run_hanami_command(command)
    @_hanami_command_line.call(command)
  end
end

Hanami::CLI::RakeTasks.install_tasks
