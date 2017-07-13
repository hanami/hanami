require 'hanami/generators/database_config'
require 'hanami/generators/test_framework'
require 'hanami/generators/template_engine'

module Hanami
  module CommandLine
    class New
      include Hanami::Cli::Command
      register 'new'

      DEFAULT_APPLICATION_NAME = 'web'.freeze
      DEFAULT_APPLICATION_BASE_URL = '/'.freeze

      attr_reader :target_path

      desc 'Generate a new hanami project'

      argument :project_name, required: true
      option :database, aliases: ['-d', '--db'], desc: "Application database (#{Hanami::Generators::DatabaseConfig::SUPPORTED_ENGINES.keys.join('/')})", default: Hanami::Generators::DatabaseConfig::DEFAULT_ENGINE
      option :application_name, desc: 'Application name, only for container', default: DEFAULT_APPLICATION_NAME
      option :application_base_url, desc: 'Application base url', default: DEFAULT_APPLICATION_BASE_URL
      option :template, desc: "Template engine (#{Hanami::Generators::TemplateEngine::SUPPORTED_ENGINES.join('/')})", default: Hanami::Generators::TemplateEngine::DEFAULT_ENGINE
      option :test, desc: "Project test framework (#{Hanami::Generators::TestFramework::VALID_FRAMEWORKS.join('/')})", default: Hanami::Hanamirc::DEFAULT_TEST_SUITE
      option :hanami_head, desc: 'Use hanami HEAD (true/false)', type: :boolean, default: false

      def call(project_name:, **options)
        # TODO: extract this operation into a mixin
        options = Hanami.environment.to_options.merge(options)

        project_name    = Utils::String.new(project_name).underscore
        database_config = Hanami::Generators::DatabaseConfig.new(options[:database], project_name)
        test_framework  = Hanami::Generators::TestFramework.new(hanamirc, options[:test])
        template_engine = Hanami::Generators::TemplateEngine.new(hanamirc, options[:template])

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
        FileUtils.mkdir_p(directory)
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
        destination   = File.join(".hanamirc")
        template_path = File.join(__dir__, "new", "hanamirc.erb")
        create_file(destination, template_path, context)

        destination   = File.join(".env.development")
        template_path = File.join(__dir__, "new", ".env.development.erb")
        create_file(destination, template_path, context)

        destination   = File.join(".env.test")
        template_path = File.join(__dir__, "new", ".env.test.erb")
        create_file(destination, template_path, context)

        destination   = File.join("README.md")
        template_path = File.join(__dir__, "new", "README.md.erb")
        create_file(destination, template_path, context)

        destination   = File.join("Gemfile")
        template_path = File.join(__dir__, "new", "Gemfile.erb")
        create_file(destination, template_path, context)

        destination   = File.join("config.ru")
        template_path = File.join(__dir__, "new", "config.ru.erb")
        create_file(destination, template_path, context)

        destination   = File.join("config", "boot.rb")
        template_path = File.join(__dir__, "new", "config", "boot.erb")
        create_file(destination, template_path, context)

        destination   = File.join("config", "environment.rb")
        template_path = File.join(__dir__, "new", "config", "environment.erb")
        create_file(destination, template_path, context)

        destination   = File.join("lib", "#{context.project_name}.rb")
        template_path = File.join(__dir__, "new", "lib", "project.erb")
        create_file(destination, template_path, context)
      end

      def generate_empty_directories(context)
        template_path = File.join(__dir__, "new", ".gitkeep.erb")

        destination = File.join("public", ".gitkeep")
        create_file(destination, template_path, context)

        destination = File.join("config", "initializers", ".gitkeep")
        create_file(destination, template_path, context)

        destination = File.join("lib", context.project_name, "entities", ".gitkeep")
        create_file(destination, template_path, context)

        destination = File.join("lib", context.project_name, "repositories", ".gitkeep")
        create_file(destination, template_path, context)

        destination = File.join("lib", context.project_name, "mailers", ".gitkeep")
        create_file(destination, template_path, context)

        destination = File.join("lib", context.project_name, "mailers", "templates", ".gitkeep")
        create_file(destination, template_path, context)

        destination = File.join("spec", context.project_name, "entities", ".gitkeep")
        create_file(destination, template_path, context)

        destination = File.join("spec", context.project_name, "repositories", ".gitkeep")
        create_file(destination, template_path, context)

        destination = File.join("spec", context.project_name, "mailers", ".gitkeep")
        create_file(destination, template_path, context)

        destination = File.join("spec", "support", ".gitkeep")
        create_file(destination, template_path, context)

        if context.database_config.sql?
          destination = File.join("db", "migrations", ".gitkeep")
          create_file(destination, template_path, context)
        else
          destination = File.join("db", ".gitkeep")
          create_file(destination, template_path, context)
        end
      end

      def generate_test_templates(context)
        if context.test_framework.rspec?
          destination   = File.join("Rakefile")
          template_path = File.join(__dir__, "new", "rspec", "Rakefile.erb")
          create_file(destination, template_path, context)

          destination   = File.join(".rspec")
          template_path = File.join(__dir__, "new", "rspec", "rspec.erb")
          create_file(destination, template_path, context)

          destination   = File.join("spec", "spec_helper.rb")
          template_path = File.join(__dir__, "new", "rspec", "spec_helper.erb")
          create_file(destination, template_path, context)

          destination   = File.join("spec", "features_helper.rb")
          template_path = File.join(__dir__, "new", "rspec", "features_helper.erb")
          create_file(destination, template_path, context)

          destination   = File.join("spec", "support", "capybara.rb")
          template_path = File.join(__dir__, "new", "rspec", "capybara.erb")
          create_file(destination, template_path, context)
        else # minitest (default)
          destination   = File.join("Rakefile")
          template_path = File.join(__dir__, "new", "minitest", "Rakefile.erb")
          create_file(destination, template_path, context)

          destination   = File.join("spec", "spec_helper.rb")
          template_path = File.join(__dir__, "new", "minitest", "spec_helper.erb")
          create_file(destination, template_path, context)

          destination   = File.join("spec", "features_helper.rb")
          template_path = File.join(__dir__, "new", "minitest", "features_helper.erb")
          create_file(destination, template_path, context)
        end
      end

      def generate_sql_templates(context)
        return unless context.database_config.sql?

        destination   = File.join("db", "schema.sql")
        template_path = File.join(__dir__, "new", "schema.sql.erb")
        create_file(destination, template_path, context)
      end

      def generate_git_templates(context)
        return if git_dir_present?

        destination   = File.join(".gitignore")
        source        = context.database_config.sqlite? ? 'gitignore_with_sqlite.erb' : 'gitignore.erb'
        template_path = File.join(__dir__, "new", source)
        create_file(destination, template_path, context)
      end

      def target_path
        Pathname.pwd
      end

      def generate_app(context)
        Hanami::CommandLine::Generate::App.new(nil).call(app: context.application_name, application_base_url: context.application_base_url, **context.options)
      end

      def init_git
        return if git_dir_present?

        say(:run, "git init . from \".\"")
        system("git init #{Shellwords.escape(target)}", out: File::NULL)
      end

      def git_dir_present?
        File.directory?(target.join('.git'))
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

      FORMATTER = "%<operation>12s  %<path>s\n".freeze

      def say(operation, path)
        puts(FORMATTER % { operation: operation, path: path })
      end

      def create_file(destination, template_path, context)
        template = File.read(template_path)
        renderer = Renderer.new
        output   = renderer.call(template, context.binding)

        FileUtils.mkpath(File.dirname(destination))
        File.open(destination, "wb") { |f| f.write(output) }

        say(:create, destination)
      end
    end
  end
end
