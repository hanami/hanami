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
          add_git_templates
        end

        def template_options
          {
            app_name:             app_name,
            hanami_head:          hanami_head?,
            test:                 test_framework.framework,
            database:             database_config.type,
            database_config:      database_config.to_hash,
            hanami_model_version: hanami_model_version,
            hanami_version:       hanami_version,
            template:             template_engine.name
          }
        end

        def post_process_templates
          init_git
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
          add_mapping('lib/app_name.rb.tt', "lib/#{ app_name }.rb")
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
          add_mapping('.gitkeep', 'public/.gitkeep')
          add_mapping('.gitkeep', 'config/initializers/.gitkeep')
          add_mapping('.gitkeep', "lib/#{ app_name }/entities/.gitkeep")
          add_mapping('.gitkeep', "lib/#{ app_name }/repositories/.gitkeep")
          add_mapping('.gitkeep', "lib/#{ app_name }/mailers/.gitkeep")
          add_mapping('.gitkeep', "lib/#{ app_name }/mailers/templates/.gitkeep")
          add_mapping('.gitkeep', "spec/#{ app_name }/entities/.gitkeep")
          add_mapping('.gitkeep', "spec/#{ app_name }/repositories/.gitkeep")
          add_mapping('.gitkeep', "spec/#{ app_name }/mailers/.gitkeep")
          add_mapping('.gitkeep', 'spec/support/.gitkeep')

          if database_config.sql?
            add_mapping('.gitkeep', 'db/migrations/.gitkeep')
          else
            add_mapping('.gitkeep', 'db/.gitkeep')
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
