require 'shellwords'
require 'hanami/application_name'
require 'hanami/generators/database_config'
require 'hanami/generators/generatable'
require 'hanami/generators/test_framework'
require 'hanami/generators/template_engine'
require 'hanami/utils/hash'

module Hanami
  module Commands
    class New
      class Abstract

        include Hanami::Generators::Generatable

        DEFAULT_ARCHITECTURE = 'container'.freeze
        DEFAULT_APPLICATION_BASE_URL = '/'.freeze

        attr_reader :options, :target_path, :database_config,
          :test_framework, :hanami_model_version, :template_engine

        def initialize(options, name)
          @options = Hanami::Utils::Hash.new(options).symbolize!
          @name = name
          @options[:database] ||= Hanami::Generators::DatabaseConfig::DEFAULT_ENGINE

          assert_options!
          assert_name!
          assert_architecture!

          @hanami_model_version = '~> 0.7'
          @database_config = Hanami::Generators::DatabaseConfig.new(options[:database], app_name)
          @test_framework = Hanami::Generators::TestFramework.new(hanamirc, @options[:test])
          @template_engine = Hanami::Generators::TemplateEngine.new(hanamirc, @options[:template])
        end

        def start
          FileUtils.mkdir_p(app_name)
          Dir.chdir(app_name) do
            @target_path = Pathname.pwd

            super
          end
        end

        private

        def hanamirc
          @hanamirc ||= Hanamirc.new(Pathname.new('.'))
        end

        def start_in_app_dir
          raise NotImplementedError
        end

        def add_sql_templates
          return if !database_config.sql?

          add_mapping('schema.sql.tt', 'db/schema.sql')
        end

        def add_git_templates
          return if git_dir_present?

          source = database_config.filesystem? ? 'gitignore_with_db.tt' : 'gitignore.tt'
          target = '.gitignore'
          add_mapping(source, target)
        end

        def real_app_name
          @name == '.' ? ::File.basename(Dir.getwd) : @name
        end

        def app_name
          ApplicationName.new(real_app_name)
        end

        def target
          Pathname.new('.')
        end

        def init_git
          return if git_dir_present?

          generator.run("git init #{Shellwords.escape(target)}", capture: true)
        end

        def git_dir_present?
          File.directory?(target.join('.git'))
        end

        def hanami_version
          "~> #{Hanami::VERSION.scan(/\A\d{1,2}\.\d{1,2}/).first}"
        end

        def hanami_head?
          options.fetch(:hanami_head, false)
        end

        def architecture
          options.fetch(:architecture, DEFAULT_ARCHITECTURE)
        end

        def assert_name!
          if argument_blank?(@name) || @name.include?(File::SEPARATOR)
            raise ArgumentError.new("APPLICATION_NAME is required and must not contain #{File::SEPARATOR}.")
          end
        end

        def assert_architecture!
          if !['app', 'container'].include?(architecture)
            raise ArgumentError.new("Architecture must be one of 'app', 'container' but was '#{architecture}'")
          end
        end

        def application_base_url
          options[:application_base_url] || DEFAULT_APPLICATION_BASE_URL
        end

        def assert_options!
          if options.nil?
            raise ArgumentError.new('options must not be nil')
          end
        end
      end
    end
  end
end
