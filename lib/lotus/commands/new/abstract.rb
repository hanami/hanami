require 'shellwords'
require 'lotus/application_name'
require 'lotus/generators/database_config'
require 'lotus/generators/generatable'
require 'lotus/generators/test_framework'
require 'lotus/utils/hash'

module Lotus
  module Commands
    class New
      class Abstract

        include Lotus::Generators::Generatable

        DEFAULT_ARCHITECTURE = 'container'.freeze
        DEFAULT_APPLICATION_BASE_URL = '/'.freeze

        attr_reader :options, :target_path, :database_config, :test_framework

        def initialize(options, name)
          @options = Lotus::Utils::Hash.new(options).symbolize!
          @name = name
          @options[:database] ||= Lotus::Generators::DatabaseConfig::DEFAULT_ENGINE

          assert_options!
          assert_name!
          assert_architecture!

          @lotus_model_version = '~> 0.5'
          @database_config = Lotus::Generators::DatabaseConfig.new(options[:database], app_name)
          @test_framework = Lotus::Generators::TestFramework.new(options[:test])
        end

        def start
          FileUtils.mkdir_p(real_app_name)
          Dir.chdir(real_app_name) do
            @target_path = Pathname.pwd

            super
          end
        end

        private

        def lotusrc_options
          @lotusrc_options ||= Lotusrc.new(Pathname.new('.')).read
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

          source = database_config.filesystem? ? 'gitignore.tt' : '.gitignore'
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

        def lotus_model_version
          @lotus_model_version
        end

        def lotus_head?
          options.fetch(:lotus_head, false)
        end

        def architecture
          options.fetch(:architecture, DEFAULT_ARCHITECTURE)
        end

        def assert_name!
          if @name.nil? || @name.strip == '' || @name.include?(File::SEPARATOR)
            raise ArgumentError.new("APPLICATION_NAME is requried and must not contain #{File::SEPARATOR}.")
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
