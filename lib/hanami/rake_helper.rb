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
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def install
      require 'hanami/environment'
      Hanami::Environment.new.require_project_environment
      Components.resolve('model.bundled')

      desc "Preload project configuration"
      task :preload do
      end

      desc "Load the full project"
      task environment: :preload do
        Components.resolve('apps')
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
      namespace :db do
        task :migrate do
          system("bundle exec hanami db migrate") || exit($?.exitstatus)
        end
      end unless Components['model.bundled'].nil?

      namespace :assets do
        task :precompile do
          system("bundle exec hanami assets precompile") || exit($?.exitstatus)
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
  end
end
