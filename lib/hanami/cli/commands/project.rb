require "hanami/utils/file_list"

module Hanami
  module Cli
    module Commands
      module Project
        def self.readme(context)
          root.join("README.md")
        end

        def self.gemfile(context)
          root.join("Gemfile")
        end

        def self.rakefile(context)
          root.join("Rakefile")
        end

        def self.hanamirc(context)
          root.join(".hanamirc")
        end

        def self.gitignore(context)
          root.join(".gitignore")
        end

        def self.config_ru(context)
          root.join("config.ru")
        end

        def self.environment(context)
          root.join("config", "environment.rb")
        end

        def self.boot(context)
          root.join("config", "boot.rb")
        end

        def self.initializers(context)
          root.join("config", "initializers")
        end

        def self.env(context, environment)
          root.join(".env.#{environment}")
        end

        def self.db(context)
          root.join("db")
        end

        def self.db_schema(context)
          root.join("db", "schema.sql")
        end

        def self.migrations(context)
          root.join("db", "migrations")
        end

        def self.migration(context)
          timestamp = Time.now.utc.strftime(MIGRATION_TIMESTAMP_FORMAT)
          filename  = MIGRATION_FILENAME_PATTERN % { timestamp: timestamp, name: context.migration }

          root.join("db", "migrations", "#{filename}.rb")
        end

        def self.find_migration(context)
          list(root.join("db", "migrations", "*_#{context.migration}.rb")).first
        end

        def self.project(context)
          root.join("lib", "#{context.options.fetch(:project)}.rb")
        end

        def self.mailers(context)
          root.join("lib", context.options.fetch(:project), "mailers")
        end

        def self.mailers_templates(context)
          root.join("lib", context.options.fetch(:project), "mailers", "templates")
        end

        def self.mailer(context)
          root.join("lib", context.options.fetch(:project), "mailers", "#{context.mailer}.rb")
        end

        def self.mailer_templates(context)
          list root.join("lib", context.options.fetch(:project), "mailers", "templates", "#{context.mailer}.*.*")
        end

        def self.entities(context)
          root.join("lib", context.options.fetch(:project), "entities")
        end

        def self.entity(context)
          root.join("lib", context.options.fetch(:project), "entities", "#{context.model}.rb")
        end

        def self.repositories(context)
          root.join("lib", context.options.fetch(:project), "repositories")
        end

        def self.repository(context)
          root.join("lib", context.options.fetch(:project), "repositories", "#{context.model}_repository.rb")
        end

        def self.public_directory(context)
          root.join("public")
        end

        def self.assets_manifest(context)
          root.join("public", "assets.json")
        end

        def self.public_app_assets(context)
          # FIXME: extract this URL to path conversion into Hanami::Utils
          assets_directory = context.base_url.sub(/\A\//, "").split("/")
          root.join("public", "assets", *assets_directory)
        end

        def self.mailer_template(context, format)
          root.join("lib", context.options.fetch(:project), "mailers", "templates", "#{context.mailer}.#{format}.#{context.options.fetch(:template)}")
        end

        def self.app_application(context)
          root.join("apps", context.app, "application.rb")
        end

        def self.app_routes(context)
          root.join("apps", context.app, "config", "routes.rb")
        end

        def self.app_layout(context)
          root.join("apps", context.app, "views", "application_layout.rb")
        end

        def self.app_template(context)
          root.join("apps", context.app, "templates", "application.html.#{context.template}")
        end

        def self.app_favicon(context)
          root.join("apps", context.app, "assets", "favicon.ico")
        end

        def self.controllers(context)
          root.join("apps", context.app, "controllers")
        end

        def self.images(context)
          root.join("apps", context.app, "assets", "images")
        end

        def self.javascripts(context)
          root.join("apps", context.app, "assets", "javascripts")
        end

        def self.stylesheets(context)
          root.join("apps", context.app, "assets", "stylesheets")
        end

        def self.action(context)
          root.join("apps", context.app, "controllers", context.controller, "#{context.action}.rb")
        end

        def self.view(context)
          root.join("apps", context.app, "views", context.controller, "#{context.action}.rb")
        end

        def self.template(context)
          root.join("apps", context.app, "templates", context.controller, "#{context.action}.html.#{context.options.fetch(:template)}")
        end

        def self.templates(context)
          list root.join("apps", context.app, "templates", context.controller, "#{context.action}.*.*")
        end

        def self.entities_spec(context)
          root.join("spec", context.options.fetch(:project), "entities")
        end

        def self.entity_spec(context)
          root.join("spec", context.options.fetch(:project), "entities", "#{context.model}_spec.rb")
        end

        def self.repositories_spec(context)
          root.join("spec", context.options.fetch(:project), "repositories")
        end

        def self.repository_spec(context)
          root.join("spec", context.options.fetch(:project), "repositories", "#{context.model}_repository_spec.rb")
        end

        def self.mailers_spec(context)
          root.join("spec", context.options.fetch(:project), "mailers")
        end

        def self.mailer_spec(context)
          root.join("spec", context.options.fetch(:project), "mailers", "#{context.mailer}_spec.rb")
        end

        def self.app_spec(context)
          root.join("spec", context.app)
        end

        def self.app_layout_spec(context)
          root.join("spec", context.app, "views", "application_layout_spec.rb")
        end

        def self.controllers_spec(context)
          root.join("spec", context.app, "controllers")
        end

        def self.action_spec(context)
          root.join("spec", context.app, "controllers", context.controller, "#{context.action}_spec.rb")
        end

        def self.view_spec(context)
          root.join("spec", context.app, "views", context.controller, "#{context.action}_spec.rb")
        end

        def self.features_spec(context)
          root.join("spec", context.app, "features")
        end

        def self.dotrspec(context)
          root.join(".rspec")
        end

        def self.spec_helper(context)
          root.join("spec", "spec_helper.rb")
        end

        def self.features_helper(context)
          root.join("spec", "features_helper.rb")
        end

        def self.support_spec(context)
          root.join("spec", "support")
        end

        def self.capybara(context)
          root.join("spec", "support", "capybara.rb")
        end

        def self.app(context)
          root.join("apps", context.app)
        end

        def self.app?(context)
          apps.include?(context.app)
        end

        def self.apps
          Dir.glob(root.join("apps", "*")).map { |app| File.basename(app) }
        end

        def self.keep(path)
          root.join(path, ".gitkeep")
        end

        def self.list(pattern)
          Hanami::Utils::FileList[pattern]
        end

        def self.root
          File
        end

        private

        MIGRATION_TIMESTAMP_FORMAT = "%Y%m%d%H%M%S".freeze
        MIGRATION_FILENAME_PATTERN = "%{timestamp}_%{name}".freeze
      end
    end
  end
end
