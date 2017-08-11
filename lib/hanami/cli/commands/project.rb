require "hanami/utils/file_list"
require "securerandom"

module Hanami
  # Hanami CLI
  #
  # @since 1.1.0
  class CLI
    module Commands
      # @since 1.1.0
      # @api private
      module Project # rubocop:disable Metrics/ModuleLength
        # @since 1.1.0
        # @api private
        def self.readme(*)
          root.join("README.md")
        end

        # @since 1.1.0
        # @api private
        def self.gemfile(*)
          root.join("Gemfile")
        end

        # @since 1.1.0
        # @api private
        def self.rakefile(*)
          root.join("Rakefile")
        end

        # @since 1.1.0
        # @api private
        def self.hanamirc(*)
          root.join(".hanamirc")
        end

        # @since 1.1.0
        # @api private
        def self.gitignore(*)
          root.join(".gitignore")
        end

        # @since 1.1.0
        # @api private
        def self.config_ru(*)
          root.join("config.ru")
        end

        # @since 1.1.0
        # @api private
        def self.environment(*)
          root.join("config", "environment.rb")
        end

        # @since 1.1.0
        # @api private
        def self.boot(*)
          root.join("config", "boot.rb")
        end

        # @since 1.1.0
        # @api private
        def self.initializers(*)
          root.join("config", "initializers")
        end

        # @since 1.1.0
        # @api private
        def self.env(*, environment)
          root.join(".env.#{environment}")
        end

        # @since 1.1.0
        # @api private
        def self.db(*)
          root.join("db")
        end

        # @since 1.1.0
        # @api private
        def self.db_schema(*)
          root.join("db", "schema.sql")
        end

        # @since 1.1.0
        # @api private
        def self.migrations(*)
          root.join("db", "migrations")
        end

        # @since 1.1.0
        # @api private
        def self.migration(context)
          filename = MIGRATION_FILENAME_PATTERN % { timestamp: migration_timestamp, name: context.migration }

          root.join("db", "migrations", "#{filename}.rb")
        end

        # @since 1.1.0
        # @api private
        def self.migration_timestamp
          Time.now.utc.strftime(MIGRATION_TIMESTAMP_FORMAT)
        end

        # @since 1.1.0
        # @api private
        def self.find_migration(context)
          list(root.join("db", "migrations", "*_#{context.migration}.rb")).first
        end

        # @since 1.1.0
        # @api private
        def self.project(context)
          root.join("lib", "#{context.options.fetch(:project)}.rb")
        end

        # @since 1.1.0
        # @api private
        def self.mailers(context)
          root.join("lib", context.options.fetch(:project), "mailers")
        end

        # @since 1.1.0
        # @api private
        def self.mailers_templates(context)
          root.join("lib", context.options.fetch(:project), "mailers", "templates")
        end

        # @since 1.1.0
        # @api private
        def self.mailer(context)
          root.join("lib", context.options.fetch(:project), "mailers", "#{context.mailer}.rb")
        end

        # @since 1.1.0
        # @api private
        def self.mailer_templates(context)
          list root.join("lib", context.options.fetch(:project), "mailers", "templates", "#{context.mailer}.*.*")
        end

        # @since 1.1.0
        # @api private
        def self.entities(context)
          root.join("lib", context.options.fetch(:project), "entities")
        end

        # @since 1.1.0
        # @api private
        def self.entity(context)
          root.join("lib", context.options.fetch(:project), "entities", "#{context.model}.rb")
        end

        # @since 1.1.0
        # @api private
        def self.repositories(context)
          root.join("lib", context.options.fetch(:project), "repositories")
        end

        # @since 1.1.0
        # @api private
        def self.repository(context)
          root.join("lib", context.options.fetch(:project), "repositories", "#{context.model}_repository.rb")
        end

        # @since 1.1.0
        # @api private
        def self.public_directory(*)
          root.join("public")
        end

        # @since 1.1.0
        # @api private
        def self.assets_manifest(*)
          root.join("public", "assets.json")
        end

        # @since 1.1.0
        # @api private
        def self.public_app_assets(context)
          # FIXME: extract this URL to path conversion into Hanami::Utils
          assets_directory = context.base_url.sub(/\A\//, "").split("/")
          root.join("public", "assets", *assets_directory)
        end

        # @since 1.1.0
        # @api private
        def self.mailer_template(context, format)
          root.join("lib", context.options.fetch(:project), "mailers", "templates", "#{context.mailer}.#{format}.#{context.options.fetch(:template)}")
        end

        # @since 1.1.0
        # @api private
        def self.app_application(context)
          root.join("apps", context.app, "application.rb")
        end

        # @since 1.1.0
        # @api private
        def self.app_sessions_secret
          SecureRandom.hex(32)
        end

        # @since 1.1.0
        # @api private
        def self.app_routes(context)
          root.join("apps", context.app, "config", "routes.rb")
        end

        # @since 1.1.0
        # @api private
        def self.app_layout(context)
          root.join("apps", context.app, "views", "application_layout.rb")
        end

        # @since 1.1.0
        # @api private
        def self.app_template(context)
          root.join("apps", context.app, "templates", "application.html.#{context.template}")
        end

        # @since 1.1.0
        # @api private
        def self.app_favicon(context)
          root.join("apps", context.app, "assets", "favicon.ico")
        end

        # @since 1.1.0
        # @api private
        def self.controllers(context)
          root.join("apps", context.app, "controllers")
        end

        # @since 1.1.0
        # @api private
        def self.images(context)
          root.join("apps", context.app, "assets", "images")
        end

        # @since 1.1.0
        # @api private
        def self.javascripts(context)
          root.join("apps", context.app, "assets", "javascripts")
        end

        # @since 1.1.0
        # @api private
        def self.stylesheets(context)
          root.join("apps", context.app, "assets", "stylesheets")
        end

        # @since 1.1.0
        # @api private
        def self.action(context)
          root.join("apps", context.app, "controllers", context.controller, "#{context.action}.rb")
        end

        # @since 1.1.0
        # @api private
        def self.view(context)
          root.join("apps", context.app, "views", context.controller, "#{context.action}.rb")
        end

        # @since 1.1.0
        # @api private
        def self.template(context)
          root.join("apps", context.app, "templates", context.controller, "#{context.action}.html.#{context.options.fetch(:template)}")
        end

        # @since 1.1.0
        # @api private
        def self.templates(context)
          list root.join("apps", context.app, "templates", context.controller, "#{context.action}.*.*")
        end

        # @since 1.1.0
        # @api private
        def self.entities_spec(context)
          root.join("spec", context.options.fetch(:project), "entities")
        end

        # @since 1.1.0
        # @api private
        def self.entity_spec(context)
          root.join("spec", context.options.fetch(:project), "entities", "#{context.model}_spec.rb")
        end

        # @since 1.1.0
        # @api private
        def self.repositories_spec(context)
          root.join("spec", context.options.fetch(:project), "repositories")
        end

        # @since 1.1.0
        # @api private
        def self.repository_spec(context)
          root.join("spec", context.options.fetch(:project), "repositories", "#{context.model}_repository_spec.rb")
        end

        # @since 1.1.0
        # @api private
        def self.mailers_spec(context)
          root.join("spec", context.options.fetch(:project), "mailers")
        end

        # @since 1.1.0
        # @api private
        def self.mailer_spec(context)
          root.join("spec", context.options.fetch(:project), "mailers", "#{context.mailer}_spec.rb")
        end

        # @since 1.1.0
        # @api private
        def self.app_spec(context)
          root.join("spec", context.app)
        end

        def self.app_layout_spec(context)
          root.join("spec", context.app, "views", "application_layout_spec.rb")
        end

        # @since 1.1.0
        # @api private
        def self.controllers_spec(context)
          root.join("spec", context.app, "controllers")
        end

        # @since 1.1.0
        # @api private
        def self.action_spec(context)
          root.join("spec", context.app, "controllers", context.controller, "#{context.action}_spec.rb")
        end

        # @since 1.1.0
        # @api private
        def self.view_spec(context)
          root.join("spec", context.app, "views", context.controller, "#{context.action}_spec.rb")
        end

        # @since 1.1.0
        # @api private
        def self.features_spec(context)
          root.join("spec", context.app, "features")
        end

        # @since 1.1.0
        # @api private
        def self.dotrspec(*)
          root.join(".rspec")
        end

        # @since 1.1.0
        # @api private
        def self.spec_helper(*)
          root.join("spec", "spec_helper.rb")
        end

        # @since 1.1.0
        # @api private
        def self.features_helper(*)
          root.join("spec", "features_helper.rb")
        end

        # @since 1.1.0
        # @api private
        def self.support_spec(*)
          root.join("spec", "support")
        end

        # @since 1.1.0
        # @api private
        def self.capybara(*)
          root.join("spec", "support", "capybara.rb")
        end

        # @since 1.1.0
        # @api private
        def self.app(context)
          root.join("apps", context.app)
        end

        # @since 1.1.0
        # @api private
        def self.app?(context)
          apps.include?(context.app)
        end

        # @since 1.1.0
        # @api private
        def self.apps
          Dir.glob(root.join("apps", "*")).map { |app| File.basename(app) }
        end

        # @since 1.1.0
        # @api private
        def self.keep(path)
          root.join(path, ".gitkeep")
        end

        # @since 1.1.0
        # @api private
        def self.list(pattern)
          Hanami::Utils::FileList[pattern]
        end

        # @since 1.1.0
        # @api private
        def self.root
          File
        end

        # @since 1.1.0
        # @api private
        MIGRATION_TIMESTAMP_FORMAT = "%Y%m%d%H%M%S".freeze

        # @since 1.1.0
        # @api private
        MIGRATION_FILENAME_PATTERN = "%{timestamp}_%{name}".freeze # rubocop:disable Style/FormatStringToken
      end
    end
  end
end
