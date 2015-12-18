require 'rake'

module Lotus
  # Install Rake tasks in projects
  #
  # @since x.x.x
  # @api private
  class RakeHelper
    include Rake::DSL

    # @since x.x.x
    # @api private
    def self.install_tasks
      new.install
    end

    # @since x.x.x
    # @api private
    def install
      desc "Preload project configuration"
      task :preload do
        require 'lotus/environment'
        Lotus::Environment.new
      end

      desc "Load the full project"
      task environment: :preload do
        require Lotus::Environment.new.env_config
        Lotus::Application.preload_applications!
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
      # want to encourage developers to use `lotus` commands.
      #
      # In order to migrate the database or precompile assets a developer should
      # use:
      #
      #   * lotus db migrate
      #   * lotus assets precompile
      #
      # This is the preferred way to run Lotus command line tasks.
      # Please use them when you're in control of your deployment environment.
      namespace :db do
        task :migrate do
          system "bundle exec lotus db migrate"
        end
      end

      namespace :assets do
        task :precompile do
          system "bundle exec lotus assets precompile"
        end
      end
    end
  end
end
