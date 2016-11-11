require 'hanami/commands/generate/app'
require 'hanami/commands/new/abstract'

module Hanami
  module Commands
    class New
      class Container < Abstract

        DEFAULT_APPLICATION_NAME = 'web'.freeze

        def map_templates
          add_application_templates
          add_empty_directories
          add_test_templates
          add_sql_templates
          add_git_templates if git_available?
        end

        def template_options
          {
            project_name:         project_name,
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

        def post_process_templates
          init_git if git_available?
          generate_app
        end

        private

        def add_application_templates
          add_mapping('hanamirc.tt', '.hanamirc')
          add_mapping('.env.development.tt', '.env.development')
          add_mapping('.env.test.tt', '.env.test')
          add_mapping('Gemfile.tt', 'Gemfile')
          add_mapping('config.ru.tt', 'config.ru')
          add_mapping('config/environment.rb.tt', 'config/environment.rb')
          add_mapping('lib/project.rb.tt', "lib/#{ project_name }.rb")
        end

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

        def add_empty_directories
          add_mapping('.keep', 'public/.keep')
          add_mapping('.keep', 'config/initializers/.keep')
          add_mapping('.keep', "lib/#{ project_name }/entities/.keep")
          add_mapping('.keep', "lib/#{ project_name }/repositories/.keep")
          add_mapping('.keep', "lib/#{ project_name }/mailers/.keep")
          add_mapping('.keep', "lib/#{ project_name }/mailers/templates/.keep")
          add_mapping('.keep', "spec/#{ project_name }/entities/.keep")
          add_mapping('.keep', "spec/#{ project_name }/repositories/.keep")
          add_mapping('.keep', "spec/#{ project_name }/mailers/.keep")
          add_mapping('.keep', 'spec/support/.keep')

          if database_config.sql?
            add_mapping('.keep', 'db/migrations/.keep')
          else
            add_mapping('.keep', 'db/.keep')
          end
        end

        def generate_app
          Hanami::Commands::Generate::App.new(app_options, app_slice_name).start
        end

        def app_options
          {
            application_base_url: application_base_url
          }
        end

        def app_slice_name
          options.fetch(:application_name, DEFAULT_APPLICATION_NAME)
        end

        def template_source_path
          Pathname.new(::File.dirname(__FILE__)).join('..', '..', 'generators', 'application', 'container').realpath
        end
      end
    end
  end
end
