module Hanami
  class Cli
    module Commands
      class New < Command
        class DatabaseConfig
          # @api private
          SUPPORTED_ENGINES = {
            'mysql'      => { type: :sql,         mri: 'mysql2',  jruby: 'jdbc-mysql'    },
            'mysql2'     => { type: :sql,         mri: 'mysql2',  jruby: 'jdbc-mysql'    },
            'postgresql' => { type: :sql,         mri: 'pg',      jruby: 'jdbc-postgres' },
            'postgres'   => { type: :sql,         mri: 'pg',      jruby: 'jdbc-postgres' },
            'sqlite'     => { type: :sql,         mri: 'sqlite3', jruby: 'jdbc-sqlite3'  },
            'sqlite3'    => { type: :sql,         mri: 'sqlite3', jruby: 'jdbc-sqlite3'  }
          }.freeze

          # @api private
          DEFAULT_ENGINE = 'sqlite'.freeze

          # @api private
          attr_reader :engine
          # @api private
          attr_reader :name

          # @api private
          def initialize(engine, name)
            @engine = engine
            @name = name

            unless SUPPORTED_ENGINES.key?(engine.to_s) # rubocop:disable Style/GuardClause
              warn %(`#{engine}' is not a valid database engine)
              exit(1)
            end
          end

          # @api private
          def to_hash
            {
              gem: gem,
              uri: uri,
              type: type
            }
          end

          # @api private
          def type
            SUPPORTED_ENGINES[engine][:type]
          end

          # @api private
          def sql?
            type == :sql
          end

          # @api private
          def sqlite?
            ['sqlite', 'sqlite3'].include?(engine)
          end

          private

          # @api private
          def platform
            Hanami::Utils.jruby? ? :jruby : :mri
          end

          # @api private
          def platform_prefix
            'jdbc:'.freeze if Hanami::Utils.jruby?
          end

          # @api private
          def uri
            {
              development: environment_uri(:development),
              test: environment_uri(:test)
            }
          end

          # @api private
          def gem
            SUPPORTED_ENGINES[engine][platform]
          end

          # @api private
          def base_uri
            case engine
            when 'mysql', 'mysql2'
              if Hanami::Utils.jruby?
                "mysql://localhost/#{ name }"
              else
                "mysql2://localhost/#{ name }"
              end
            when 'postgresql', 'postgres'
              "postgresql://localhost/#{ name }"
            when 'sqlite', 'sqlite3'
              "sqlite://db/#{ Shellwords.escape(name) }"
            end
          end

          # @api private
          def environment_uri(environment)
            case engine
            when 'sqlite', 'sqlite3'
              "#{ platform_prefix }#{ base_uri }_#{ environment }.sqlite"
            else
              "#{ platform_prefix if sql? }#{ base_uri }_#{ environment }"
            end
          end
        end

        class TestFramework
          # @api private
          RSPEC = 'rspec'.freeze
          # @api private
          MINITEST = 'minitest'.freeze
          # @api private
          VALID_FRAMEWORKS = [MINITEST, RSPEC].freeze

          # @api private
          attr_reader :framework

          # @api private
          def initialize(hanamirc, framework)
            @framework = (framework || hanamirc.options.fetch(:test))
            assert_framework!
          end

          # @api private
          def rspec?
            framework == RSPEC
          end

          # @api private
          def minitest?
            framework == MINITEST
          end

          private

          # @api private
          def assert_framework!
            if !supported_framework?
              warn "`#{framework}' is not a valid test framework. Please use one of: #{valid_test_frameworks.join(', ')}"
              exit(1)
            end
          end

          # @api private
          def valid_test_frameworks
            VALID_FRAMEWORKS.map { |name| "`#{name}'"}
          end

          # @api private
          def supported_framework?
            VALID_FRAMEWORKS.include?(framework)
          end
        end

        class TemplateEngine
          class UnsupportedTemplateEngine < ::StandardError
          end

          # @api private
          SUPPORTED_ENGINES = %w(erb haml slim).freeze
          # @api private
          DEFAULT_ENGINE = 'erb'.freeze

          # @api private
          attr_reader :name

          # @api private
          def initialize(hanamirc, engine)
            @name = (engine || hanamirc.options.fetch(:template))
            assert_engine!
          end

          private

          # @api private
          def assert_engine!
            if !supported_engine?
              warn "`#{name}' is not a valid template engine. Please use one of: #{valid_template_engines.join(', ')}"
              exit(1)
            end
          end

          # @api private
          def valid_template_engines
            SUPPORTED_ENGINES.map { |name| "`#{name}'"}
          end

          # @api private
          def supported_engine?
            SUPPORTED_ENGINES.include?(@name.to_s)
          end
        end

        DEFAULT_APPLICATION_NAME = 'web'.freeze
        DEFAULT_APPLICATION_BASE_URL = '/'.freeze

        attr_reader :target_path

        desc "Generate a new Hanami project"
        argument :project, required: true, desc: "The project name"

        option :database,             desc: "Database (#{DatabaseConfig::SUPPORTED_ENGINES.keys.join('/')})", default: DatabaseConfig::DEFAULT_ENGINE, aliases: ["-d"]
        option :application_name,     desc: "App name", default: DEFAULT_APPLICATION_NAME
        option :application_base_url, desc: "App base URL", default: DEFAULT_APPLICATION_BASE_URL
        option :template,             desc: "Template engine (#{TemplateEngine::SUPPORTED_ENGINES.join('/')})", default: TemplateEngine::DEFAULT_ENGINE
        option :test,                 desc: "Project testing framework (#{TestFramework::VALID_FRAMEWORKS.join('/')})", default: Hanami::Hanamirc::DEFAULT_TEST_SUITE
        option :hanami_head,          desc: "Use Hanami HEAD (true/false)", type: :boolean, default: false

        example [
          "bookshelf                     # Basic usage",
          "bookshelf --test=rspec        # Setup RSpec testing framework",
          "bookshelf --database=postgres # Setup Postgres database",
          "bookshelf --template=slim     # Setup Slim template engine",
          "bookshelf --hanami-head       # Use Hanami HEAD"
        ]

        def call(project:, **options)
          project         = Utils::String.new(project).underscore
          database_config = DatabaseConfig.new(options[:database], project)
          test_framework  = TestFramework.new(hanamirc, options[:test])
          template_engine = TemplateEngine.new(hanamirc, options[:template])
          options[:project] = project

          context = Context.new(
            project: project,
            database: database_config.type,
            database_config_hash: database_config.to_hash,
            database_config: database_config,
            test_framework: test_framework,
            template_engine: template_engine,
            test: options.fetch(:test),
            application_name: options.fetch(:application_name),
            application_base_url: options.fetch(:application_base_url),
            hanami_head: options.fetch(:hanami_head),
            hanami_model_version: '~> 1.0',
            code_reloading: code_reloading?,
            hanami_version: hanami_version,
            project_module: Utils::String.new(project).classify,
            options: options
          )

          assert_project_name!(context)

          directory = project_directory(project)
          files.mkdir(directory)

          Dir.chdir(directory) do
            generate_application_templates(context)
            generate_empty_directories(context)
            generate_test_templates(context)
            generate_sql_templates(context)
            generate_git_templates(context)

            init_git

            generate_app(context)
          end

          # FIXME this should be removed
          true
        end

        private

        def assert_project_name!(context)
          if context.project.include?(File::SEPARATOR)
            raise ArgumentError.new("PROJECT must not contain #{File::SEPARATOR}.")
          end
        end

        def generate_application_templates(context)
          source      = templates.find("hanamirc.erb")
          destination = project.hanamirc(context)
          generate_file(source, destination, context)

          source      = templates.find(".env.development.erb")
          destination = project.env(context, "development")
          generate_file(source, destination, context)

          source      = templates.find(".env.test.erb")
          destination = project.env(context, "test")
          generate_file(source, destination, context)

          source      = templates.find("README.md.erb")
          destination = project.readme(context)
          generate_file(source, destination, context)

          source      = templates.find("Gemfile.erb")
          destination = project.gemfile(context)
          generate_file(source, destination, context)

          source      = templates.find("config.ru.erb")
          destination = project.config_ru(context)
          generate_file(source, destination, context)

          source      = templates.find("config", "boot.erb")
          destination = project.boot(context)
          generate_file(source, destination, context)

          source      = templates.find("config", "environment.erb")
          destination = project.environment(context)
          generate_file(source, destination, context)

          source      = templates.find("lib", "project.erb")
          destination = project.project(context)
          generate_file(source, destination, context)
        end

        def generate_empty_directories(context)
          source = templates.find(".gitkeep.erb")

          destination = project.keep(project.public_directory(context))
          generate_file(source, destination, context)

          destination = project.keep(project.initializers(context))
          generate_file(source, destination, context)

          destination = project.keep(project.entities(context))
          generate_file(source, destination, context)

          destination = project.keep(project.repositories(context))
          generate_file(source, destination, context)

          destination = project.keep(project.mailers(context))
          generate_file(source, destination, context)

          destination = project.keep(project.mailers_templates(context))
          generate_file(source, destination, context)

          destination = project.keep(project.entities_spec(context))
          generate_file(source, destination, context)

          destination = project.keep(project.repositories_spec(context))
          generate_file(source, destination, context)

          destination = project.keep(project.mailers_spec(context))
          generate_file(source, destination, context)

          destination = project.keep(project.support_spec(context))
          generate_file(source, destination, context)

          if context.database_config.sql?
            destination = project.keep(project.migrations(context))
          else
            destination = project.keep(project.db(context))
          end

          generate_file(source, destination, context)
        end

        def generate_test_templates(context)
          if context.test_framework.rspec?
            source      = templates.find("rspec", "Rakefile.erb")
            destination = project.rakefile(context)
            generate_file(source, destination, context)

            source      = templates.find("rspec", "rspec.erb")
            destination = project.dotrspec(context)
            generate_file(source, destination, context)

            source      = templates.find("rspec", "spec_helper.erb")
            destination = project.spec_helper(context)
            generate_file(source, destination, context)

            source      = templates.find("rspec", "features_helper.erb")
            destination = project.features_helper(context)
            generate_file(source, destination, context)

            source      = templates.find("rspec", "capybara.erb")
            destination = project.capybara(context)
            generate_file(source, destination, context)
          else # minitest (default)
            source      = templates.find("minitest", "Rakefile.erb")
            destination = project.rakefile(context)
            generate_file(source, destination, context)

            source      = templates.find("minitest", "spec_helper.erb")
            destination = project.spec_helper(context)
            generate_file(source, destination, context)

            source      = templates.find("minitest", "features_helper.erb")
            destination = project.features_helper(context)
            generate_file(source, destination, context)
          end
        end

        def generate_sql_templates(context)
          return unless context.database_config.sql?

          source      = templates.find("schema.sql.erb")
          destination = project.db_schema(context)
          generate_file(source, destination, context)
        end

        def generate_git_templates(context)
          return if git_dir_present?

          source      = context.database_config.sqlite? ? 'gitignore_with_sqlite.erb' : 'gitignore.erb'
          source      = templates.find(source)
          destination = project.gitignore(context)

          generate_file(source, destination, context)
        end

        def target_path
          Pathname.pwd
        end

        def generate_app(context)
          Hanami::Cli::Commands::Generate::App.new(command_name: "generate app", out: @out, files: @files).call(app: context.application_name, application_base_url: context.application_base_url, **context.options)
        end

        def init_git
          return if git_dir_present?

          say(:run, "git init . from \".\"")
          system("git init #{Shellwords.escape(target)}", out: File::NULL)
        end

        def git_dir_present?
          files.directory?('.git')
        end

        def target
          Pathname.new('.')
        end

        def hanamirc
          @hanamirc ||= Hanamirc.new(Pathname.new('.'))
        end

        def project_directory(project)
          @name == '.' ? '.' : project
        end

        def code_reloading?
          !Hanami::Utils.jruby?
        end

        def hanami_version
          Hanami::Version.gem_requirement
        end

        def generate_file(source, destination, context)
          super
          say(:create, destination)
        end
      end
    end

    register "new", Commands::New
  end
end
