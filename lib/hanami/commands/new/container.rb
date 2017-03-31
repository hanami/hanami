require 'hanami/commands/generate/app'
require 'hanami/commands/new/abstract'

module Hanami
  # @api private
  module Commands
    # @api private
    class New
      # @api private
      class Container < Abstract

        # @api private
        DEFAULT_APPLICATION_NAME = 'web'.freeze

        # @api private
        def map_templates
          add_application_templates
          add_empty_directories
          add_test_templates
          add_sql_templates
          add_git_templates
        end

        # @api private
        def template_options
          {
            project_name:         project_name,
            project_module:       project_module,
            hanami_head:          hanami_head?,
            code_reloading:       code_reloading?,
            test:                 test_framework.framework,
            database:             database_config.type,
            database_config:      database_config.to_hash,
            hanami_model_version: hanami_model_version,
            hanami_version:       hanami_version,
            template:             template_engine.name
          }
        end

        # @api private
        def post_process_templates
          init_git
          generate_app
        end

        private

        # @api private
        def add_application_templates
          add_mapping('hanamirc.tt', '.hanamirc')
          add_mapping('.env.development.tt', '.env.development')
          add_mapping('.env.test.tt', '.env.test')
          add_mapping('Gemfile.tt', 'Gemfile')
          add_mapping('config.ru.tt', 'config.ru')
          add_mapping('config/boot.rb.tt', 'config/boot.rb')
          add_mapping('config/environment.rb.tt', 'config/environment.rb')
          add_mapping('lib/project.rb.tt', "lib/#{ project_name }.rb")
        end

        # @api private
        def add_test_templates
          if test_framework.rspec?
            add_mapping('Rakefile.rspec.tt', 'Rakefile')
            add_mapping('rspec.rspec.tt', '.rspec')
            add_mapping('spec_helper.rb.rspec.tt', 'spec/spec_helper.rb')
            add_mapping('features_helper.rb.rspec.tt', 'spec/features_helper.rb')
            add_mapping('capybara.rb.rspec.tt', 'spec/support/capybara.rb')
          else # minitest (default)
            add_mapping('Rakefile.minitest.tt', 'Rakefile')
            add_mapping('spec_helper.rb.minitest.tt', 'spec/spec_helper.rb')
            add_mapping('features_helper.rb.minitest.tt', 'spec/features_helper.rb')
          end
        end

        # @api private
        def add_empty_directories
          add_mapping('.gitkeep', 'public/.gitkeep')
          add_mapping('.gitkeep', 'config/initializers/.gitkeep')
          add_mapping('.gitkeep', "lib/#{ project_name }/entities/.gitkeep")
          add_mapping('.gitkeep', "lib/#{ project_name }/repositories/.gitkeep")
          add_mapping('.gitkeep', "lib/#{ project_name }/mailers/.gitkeep")
          add_mapping('.gitkeep', "lib/#{ project_name }/mailers/templates/.gitkeep")
          add_mapping('.gitkeep', "spec/#{ project_name }/entities/.gitkeep")
          add_mapping('.gitkeep', "spec/#{ project_name }/repositories/.gitkeep")
          add_mapping('.gitkeep', "spec/#{ project_name }/mailers/.gitkeep")
          add_mapping('.gitkeep', 'spec/support/.gitkeep')

          if database_config.sql?
            add_mapping('.gitkeep', 'db/migrations/.gitkeep')
          else
            add_mapping('.gitkeep', 'db/.gitkeep')
          end
        end

        # @api private
        def generate_app
          Hanami::Commands::Generate::App.new(app_options, app_slice_name).start
        end

        # @api private
        def app_options
          {
            application_base_url: application_base_url
          }
        end

        # @api private
        def app_slice_name
          options.fetch(:application_name, DEFAULT_APPLICATION_NAME)
        end

        # @api private
        def template_source_path
          Pathname.new(::File.dirname(__FILE__)).join('..', '..', 'generators', 'application', 'container').realpath
        end
      end
    end
  end
end
