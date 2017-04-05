require 'shellwords'
require 'hanami/application_name'
require 'hanami/generators/database_config'
require 'hanami/generators/generatable'
require 'hanami/generators/test_framework'
require 'hanami/generators/template_engine'
require 'hanami/utils'
require 'hanami/utils/hash'
require 'hanami/utils/string'

module Hanami
  # @api private
  module Commands
    # @api private
    class New
      # @api private
      class Abstract

        include Hanami::Generators::Generatable

        # @api private
        DEFAULT_ARCHITECTURE = 'container'.freeze
        # @api private
        DEFAULT_APPLICATION_BASE_URL = '/'.freeze

        # @api private
        attr_reader :options
        # @api private
        attr_reader :target_path
        # @api private
        attr_reader :database_config
        # @api private
        attr_reader :test_framework
        # @api private
        attr_reader :hanami_model_version
        # @api private
        attr_reader :template_engine

        # @api private
        def initialize(options, name)
          @options = Hanami::Utils::Hash.new(options).symbolize!
          @name = name
          @options[:database] ||= Hanami::Generators::DatabaseConfig::DEFAULT_ENGINE

          assert_options!
          assert_name!
          assert_architecture!

          @hanami_model_version = '~> 1.0'
          @database_config = Hanami::Generators::DatabaseConfig.new(options[:database], project_name)
          @test_framework = Hanami::Generators::TestFramework.new(hanamirc, @options[:test])
          @template_engine = Hanami::Generators::TemplateEngine.new(hanamirc, @options[:template])
        end

        # @api private
        def start
          FileUtils.mkdir_p(project_directory)
          Dir.chdir(project_directory) do
            @target_path = Pathname.pwd

            super
          end
        end

        private

        # @api private
        def hanamirc
          @hanamirc ||= Hanamirc.new(Pathname.new('.'))
        end

        # @api private
        def start_in_app_dir
          raise NotImplementedError
        end

        # @api private
        def add_sql_templates
          return if !database_config.sql?

          add_mapping('schema.sql.tt', 'db/schema.sql')
        end

        # @api private
        def add_git_templates
          return if git_dir_present?

          source = database_config.sqlite? ? 'gitignore_with_sqlite.tt' : 'gitignore.tt'
          target = '.gitignore'
          add_mapping(source, target)
        end

        # @api private
        def real_project_name
          @name == '.' ? ::File.basename(Dir.getwd) : @name
        end

        # @api private
        def project_name
          ApplicationName.new(real_project_name)
        end

        # @api private
        def project_module
          Utils::String.new(project_name).classify
        end

        # @api private
        def project_directory
          @name == '.' ? '.' : project_name
        end

        # @api private
        def target
          Pathname.new('.')
        end

        # @api private
        def init_git
          return if git_dir_present?

          generator.run("git init #{Shellwords.escape(target)}", capture: true)
        end

        # @api private
        def git_dir_present?
          File.directory?(target.join('.git'))
        end

        # @api private
        def hanami_version
          Hanami::Version.gem_requirement
        end

        # @api private
        def hanami_head?
          options.fetch(:hanami_head, false)
        end

        # @api private
        def code_reloading?
          !Hanami::Utils.jruby?
        end

        # @api private
        def architecture
          options.fetch(:architecture, DEFAULT_ARCHITECTURE)
        end

        # @api private
        def assert_name!
          if argument_blank?(@name) || @name.include?(File::SEPARATOR)
            raise ArgumentError.new("APPLICATION_NAME is required and must not contain #{File::SEPARATOR}.")
          end
        end

        # @api private
        def assert_architecture!
          if !['app', 'container'].include?(architecture)
            raise ArgumentError.new("Architecture must be one of 'app', 'container' but was '#{architecture}'")
          end
        end

        # @api private
        def application_base_url
          options[:application_base_url] || DEFAULT_APPLICATION_BASE_URL
        end

        # @api private
        def assert_options!
          if options.nil?
            raise ArgumentError.new('options must not be nil')
          end
        end
      end
    end
  end
end
