module Hanami
  module Cli
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

        desc 'Generate a new hanami project'

        argument :project_name, required: true
        option :database, aliases: ['-d', '--db'], desc: "Application database (#{DatabaseConfig::SUPPORTED_ENGINES.keys.join('/')})", default: DatabaseConfig::DEFAULT_ENGINE
        option :application_name, desc: 'Application name, only for container', default: DEFAULT_APPLICATION_NAME
        option :application_base_url, desc: 'Application base url', default: DEFAULT_APPLICATION_BASE_URL
        option :template, desc: "Template engine (#{TemplateEngine::SUPPORTED_ENGINES.join('/')})", default: TemplateEngine::DEFAULT_ENGINE
        option :test, desc: "Project test framework (#{TestFramework::VALID_FRAMEWORKS.join('/')})", default: Hanami::Hanamirc::DEFAULT_TEST_SUITE
        option :hanami_head, desc: 'Use hanami HEAD (true/false)', type: :boolean, default: false

        def call(project_name:, **options)
          # TODO: extract this operation into a mixin
          options = Hanami.environment.to_options.merge(options)

          project_name    = Utils::String.new(project_name).underscore
          database_config = DatabaseConfig.new(options[:database], project_name)
          test_framework  = TestFramework.new(hanamirc, options[:test])
          template_engine = TemplateEngine.new(hanamirc, options[:template])

          context = Context.new(
            project_name: project_name,
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
            project_module: Utils::String.new(project_name).classify,
            options: options
          )

          assert_project_name!(context)

          directory = project_directory(project_name)
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
          if context.project_name.include?(File::SEPARATOR)
            raise ArgumentError.new("PROJECT_NAME must not contain #{File::SEPARATOR}.")
          end
        end

        def generate_application_templates(context)
          destination = File.join(".hanamirc")
          source      = File.join(__dir__, "new", "hanamirc.erb")
          generate_file(source, destination, context)

          destination = File.join(".env.development")
          source      = File.join(__dir__, "new", ".env.development.erb")
          generate_file(source, destination, context)

          destination = File.join(".env.test")
          source      = File.join(__dir__, "new", ".env.test.erb")
          generate_file(source, destination, context)

          destination = File.join("README.md")
          source      = File.join(__dir__, "new", "README.md.erb")
          generate_file(source, destination, context)

          destination = File.join("Gemfile")
          source      = File.join(__dir__, "new", "Gemfile.erb")
          generate_file(source, destination, context)

          destination = File.join("config.ru")
          source      = File.join(__dir__, "new", "config.ru.erb")
          generate_file(source, destination, context)

          destination = File.join("config", "boot.rb")
          source      = File.join(__dir__, "new", "config", "boot.erb")
          generate_file(source, destination, context)

          destination = File.join("config", "environment.rb")
          source      = File.join(__dir__, "new", "config", "environment.erb")
          generate_file(source, destination, context)

          destination = File.join("lib", "#{context.project_name}.rb")
          source      = File.join(__dir__, "new", "lib", "project.erb")
          generate_file(source, destination, context)
        end

        def generate_empty_directories(context)
          source = File.join(__dir__, "new", ".gitkeep.erb")

          destination = File.join("public", ".gitkeep")
          generate_file(source, destination, context)

          destination = File.join("config", "initializers", ".gitkeep")
          generate_file(source, destination, context)

          destination = File.join("lib", context.project_name, "entities", ".gitkeep")
          generate_file(source, destination, context)

          destination = File.join("lib", context.project_name, "repositories", ".gitkeep")
          generate_file(source, destination, context)

          destination = File.join("lib", context.project_name, "mailers", ".gitkeep")
          generate_file(source, destination, context)

          destination = File.join("lib", context.project_name, "mailers", "templates", ".gitkeep")
          generate_file(source, destination, context)

          destination = File.join("spec", context.project_name, "entities", ".gitkeep")
          generate_file(source, destination, context)

          destination = File.join("spec", context.project_name, "repositories", ".gitkeep")
          generate_file(source, destination, context)

          destination = File.join("spec", context.project_name, "mailers", ".gitkeep")
          generate_file(source, destination, context)

          destination = File.join("spec", "support", ".gitkeep")
          generate_file(source, destination, context)

          if context.database_config.sql?
            destination = File.join("db", "migrations", ".gitkeep")
            generate_file(source, destination, context)
          else
            destination = File.join("db", ".gitkeep")
            generate_file(source, destination, context)
          end
        end

        def generate_test_templates(context)
          if context.test_framework.rspec?
            destination = File.join("Rakefile")
            source      = File.join(__dir__, "new", "rspec", "Rakefile.erb")
            generate_file(source, destination, context)

            destination = File.join(".rspec")
            source      = File.join(__dir__, "new", "rspec", "rspec.erb")
            generate_file(source, destination, context)

            destination = File.join("spec", "spec_helper.rb")
            source      = File.join(__dir__, "new", "rspec", "spec_helper.erb")
            generate_file(source, destination, context)

            destination = File.join("spec", "features_helper.rb")
            source      = File.join(__dir__, "new", "rspec", "features_helper.erb")
            generate_file(source, destination, context)

            destination = File.join("spec", "support", "capybara.rb")
            source      = File.join(__dir__, "new", "rspec", "capybara.erb")
            generate_file(source, destination, context)
          else # minitest (default)
            destination = File.join("Rakefile")
            source      = File.join(__dir__, "new", "minitest", "Rakefile.erb")
            generate_file(source, destination, context)

            destination = File.join("spec", "spec_helper.rb")
            source      = File.join(__dir__, "new", "minitest", "spec_helper.erb")
            generate_file(source, destination, context)

            destination = File.join("spec", "features_helper.rb")
            source      = File.join(__dir__, "new", "minitest", "features_helper.erb")
            generate_file(source, destination, context)
          end
        end

        def generate_sql_templates(context)
          return unless context.database_config.sql?

          destination = File.join("db", "schema.sql")
          source      = File.join(__dir__, "new", "schema.sql.erb")
          generate_file(source, destination, context)
        end

        def generate_git_templates(context)
          return if git_dir_present?

          destination = File.join(".gitignore")
          source      = context.database_config.sqlite? ? 'gitignore_with_sqlite.erb' : 'gitignore.erb'
          source      = File.join(__dir__, "new", source)

          generate_file(source, destination, context)
        end

        def target_path
          Pathname.pwd
        end

        def generate_app(context)
          Hanami::Cli::Commands::Generate::App.new.call(app: context.application_name, application_base_url: context.application_base_url, **context.options)
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

        def project_directory(project_name)
          @name == '.' ? '.' : project_name
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
