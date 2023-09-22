# frozen_string_literal: true

require "hanami/cli"

Hanami::CLI::RakeTasks.register_tasks do
  desc "Load the app environment"
  task :environment do
    require "hanami/prepare"
  end

  # Ruby ecosystem compatibility
  #
  # Most of the hosting SaaS automatic tasks are designed after Ruby on Rails.
  # They expect the following Rake tasks to be present:
  #
  #   * db:migrate
  #   * assets:precompile
  #
  # See https://github.com/heroku/heroku-buildpack-ruby/issues/442
  #
  # ===
  #
  # These Rake tasks are **NOT** listed when someone runs `rake -T`, because we
  # want to encourage developers to use `hanami` CLI commands.
  #
  # In order to migrate the database or compile assets a developer should use:
  #
  #   * hanami db migrate
  #   * hanami assets compile
  #
  # This is the preferred way to run Hanami command line tasks.
  # Please use them when you're in control of your deployment environment.
  #
  # If you're not in control and your deployment requires these "standard"
  # Rake tasks, they are here to solve this only specific problem.
  #
  # namespace :db do
  #   task :migrate do
  #     # TODO(@jodosha): Enable when we'll integrate with ROM
  #     # run_hanami_command("db migrate")
  #   end
  # end

  if Hanami.bundled?("hanami-assets")
    namespace :assets do
      task :precompile do
        run_hanami_command("assets compile")
      end
    end
  end

  private

  @_hanami_cli_bundler = Hanami::CLI::Bundler.new

  def run_hanami_command(command)
    @_hanami_cli_bundler.hanami_exec(command)
  end
end

Hanami::CLI::RakeTasks.install_tasks
