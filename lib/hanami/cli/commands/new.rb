require "hanami/cli/commands/generate/app"

module Hanami
  # Hanami CLI
  #
  # @since 1.1.0
  class CLI
    module Commands
      # @since 1.1.0
      # @api private
      class New < Command # rubocop:disable Metrics/ClassLength
        # @since 1.1.0
        # @api private
        class DatabaseConfig
          # @since 1.1.0
          # @api private
          SUPPORTED_ENGINES = {
            'mysql'      => { type: :sql,         mri: 'mysql2',  jruby: 'jdbc-mysql'    },
            'mysql2'     => { type: :sql,         mri: 'mysql2',  jruby: 'jdbc-mysql'    },
            'postgresql' => { type: :sql,         mri: 'pg',      jruby: 'jdbc-postgres' },
            'postgres'   => { type: :sql,         mri: 'pg',      jruby: 'jdbc-postgres' },
            'sqlite'     => { type: :sql,         mri: 'sqlite3', jruby: 'jdbc-sqlite3'  },
            'sqlite3'    => { type: :sql,         mri: 'sqlite3', jruby: 'jdbc-sqlite3'  }
          }.freeze

          # @since 1.1.0
          # @api private
          DEFAULT_ENGINE = 'sqlite'.freeze

          # @since 1.1.0
          # @api private
          attr_reader :engine

          # @since 1.1.0
          # @api private
          attr_reader :name

          # @since 1.1.0
          # @api private
          def initialize(engine, name)
            @engine = engine
            @name = name

            unless SUPPORTED_ENGINES.key?(engine.to_s) # rubocop:disable Style/GuardClause
              warn %(`#{engine}' is not a valid database engine)
              exit(1)
            end
          end

          # @since 1.1.0
          # @api private
          def to_hash
            {
              gem: gem,
              uri: uri,
              type: type
            }
          end

          # @since 1.1.0
          # @api private
          def type
            SUPPORTED_ENGINES[engine][:type]
          end

          # @since 1.1.0
          # @api private
          def sql?
            type == :sql
          end

          # @since 1.1.0
          # @api private
          def sqlite?
            %w[sqlite sqlite3].include?(engine)
          end

          private

          # @since 1.1.0
          # @api private
          def platform
            Hanami::Utils.jruby? ? :jruby : :mri
          end

          # @since 1.1.0
          # @api private
          def platform_prefix
            'jdbc:'.freeze if Hanami::Utils.jruby?
          end

          # @since 1.1.0
          # @api private
          def uri
            {
              development: environment_uri(:development),
              test: environment_uri(:test)
            }
          end

          # @since 1.1.0
          # @api private
          def gem
            SUPPORTED_ENGINES[engine][platform]
          end

          # @since 1.1.0
          # @api private
          def base_uri # rubocop:disable Metrics/MethodLength
            case engine
            when 'mysql', 'mysql2'
              if Hanami::Utils.jruby?
                "mysql://localhost/#{name}"
              else
                "mysql2://localhost/#{name}"
              end
            when 'postgresql', 'postgres'
              "postgresql://localhost/#{name}"
            when 'sqlite', 'sqlite3'
              "sqlite://db/#{Shellwords.escape(name)}"
            end
          end

          # @since 1.1.0
          # @api private
          def environment_uri(environment)
            case engine
            when 'sqlite', 'sqlite3'
              "#{platform_prefix}#{base_uri}_#{environment}.sqlite"
            else
              "#{platform_prefix if sql?}#{base_uri}_#{environment}"
            end
          end
        end

        # @since 1.1.0
        # @api private
        class TestFramework
          # @since 1.1.0
          # @api private
          RSPEC = 'rspec'.freeze

          # @since 1.1.0
          # @api private
          MINITEST = 'minitest'.freeze

          # @since 1.1.0
          # @api private
          VALID_FRAMEWORKS = [MINITEST, RSPEC].freeze

          # @since 1.1.0
          # @api private
          attr_reader :framework

          # @since 1.1.0
          # @api private
          def initialize(hanamirc, framework)
            @framework = (framework || hanamirc.options.fetch(:test))
            assert_framework!
          end

          # @since 1.1.0
          # @api private
          def rspec?
            framework == RSPEC
          end

          # @since 1.1.0
          # @api private
          def minitest?
            framework == MINITEST
          end

          private

          # @since 1.1.0
          # @api private
          def assert_framework!
            unless supported_framework? # rubocop:disable Style/GuardClause
              warn "`#{framework}' is not a valid test framework. Please use one of: #{valid_test_frameworks.join(', ')}"
              exit(1)
            end
          end

          # @since 1.1.0
          # @api private
          def valid_test_frameworks
            VALID_FRAMEWORKS.map { |name| "`#{name}'" }
          end

          # @since 1.1.0
          # @api private
          def supported_framework?
            VALID_FRAMEWORKS.include?(framework)
          end
        end

        # @since 1.1.0
        # @api private
        class TemplateEngine
          # @since 1.1.0
          # @api private
          class UnsupportedTemplateEngine < ::StandardError
          end

          # @since 1.1.0
          # @api private
          SUPPORTED_ENGINES = %w[erb haml slim].freeze

          # @since 1.1.0
          # @api private
          DEFAULT_ENGINE = 'erb'.freeze

          # @since 1.1.0
          # @api private
          attr_reader :name

          # @since 1.1.0
          # @api private
          def initialize(hanamirc, engine)
            @name = (engine || hanamirc.options.fetch(:template))
            assert_engine!
          end

          private

          # @since 1.1.0
          # @api private
          def assert_engine!
            unless supported_engine? # rubocop:disable Style/GuardClause
              warn "`#{name}' is not a valid template engine. Please use one of: #{valid_template_engines.join(', ')}"
              exit(1)
            end
          end

          # @since 1.1.0
          # @api private
          def valid_template_engines
            SUPPORTED_ENGINES.map { |name| "`#{name}'" }
          end

          # @since 1.1.0
          # @api private
          def supported_engine?
            SUPPORTED_ENGINES.include?(@name.to_s)
          end
        end

        # @since 1.1.0
        # @api private
        DEFAULT_APPLICATION_NAME = 'web'.freeze

        # @since 1.1.0
        # @api private
        DEFAULT_APPLICATION_BASE_URL = '/'.freeze

        # @since 1.1.0
        # @api private
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

        # @since 1.1.0
        # @api private
        #
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        def call(project:, **options)
          project_name = project
          pwd = ::File.basename(Dir.pwd) if project == "."
          project         = Utils::String.underscore(pwd || project)
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
            hanami_model_version: '~> 1.2',
            code_reloading: code_reloading?,
            hanami_version: hanami_version,
            project_module: Utils::String.classify(project),
            options: options
          )

          assert_project_name!(context)

          directory = project_directory(project_name, project)
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
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        private

        # @since 1.1.0
        # @api private
        def assert_project_name!(context)
          if context.project.include?(File::SEPARATOR) # rubocop:disable Style/GuardClause
            raise ArgumentError.new("PROJECT must not contain #{File::SEPARATOR}.")
          end
        end

        # @since 1.1.0
        # @api private
        #
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
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
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
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

          if context.database_config.sql? # rubocop:disable Style/ConditionalAssignment
            destination = project.keep(project.migrations(context))
          else
            destination = project.keep(project.db(context))
          end

          generate_file(source, destination, context)
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Style/IdenticalConditionalBranches
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
        # rubocop:enable Style/IdenticalConditionalBranches
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        # @since 1.1.0
        # @api private
        def generate_sql_templates(context)
          return unless context.database_config.sql?

          source      = templates.find("schema.sql.erb")
          destination = project.db_schema(context)
          generate_file(source, destination, context)
        end

        # @since 1.1.0
        # @api private
        def generate_git_templates(context)
          return if git_dir_present?

          source      = context.database_config.sqlite? ? 'gitignore_with_sqlite.erb' : 'gitignore.erb'
          source      = templates.find(source)
          destination = project.gitignore(context)

          generate_file(source, destination, context)
        end

        # @since 1.1.0
        # @api private
        def target_path
          Pathname.pwd
        end

        # @since 1.1.0
        # @api private
        def generate_app(context)
          Hanami::CLI::Commands::New::App.new(command_name: "generate app", out: @out, files: @files).call(app: context.application_name, application_base_url: context.application_base_url, **context.options)
        end

        # @since 1.1.0
        # @api private
        def init_git
          return if git_dir_present?

          say(:run, "git init . from \".\"")
          system("git init #{Shellwords.escape(target)}", out: File::NULL)
        end

        # @since 1.1.0
        # @api private
        def git_dir_present?
          files.directory?('.git')
        end

        # @since 1.1.0
        # @api private
        def target
          Pathname.new('.')
        end

        # @since 1.1.0
        # @api private
        def hanamirc
          @hanamirc ||= Hanamirc.new(Pathname.new('.'))
        end

        # @since 1.1.0
        # @api private
        def project_directory(project_name, project)
          return Dir.pwd if project_name == '.'
          project
        end

        # @since 1.1.0
        # @api private
        def code_reloading?
          !Hanami::Utils.jruby?
        end

        # @since 1.1.0
        # @api private
        def hanami_version
          Hanami::Version.gem_requirement
        end

        # @since 1.1.0
        # @api private
        def generate_file(source, destination, context)
          super
          say(:create, destination)
        end

        # @since 1.1.0
        # @api private
        class App < Commands::Generate::App
          requirements.clear

          # @since 1.1.0
          # @api private
          def initialize(*)
            super
            @templates = Templates.new(self.class.superclass)
          end
        end
      end
    end

    register "new", Commands::New
  end
end
