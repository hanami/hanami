require 'hanami/commands/new/abstract'

module Hanami
  module Commands
    class New
      class App < Abstract

        def initialize(options, name)
          super(options, name)
        end

        def map_templates
          add_application_templates
          add_empty_directories
          add_test_templates
          add_sql_templates
          add_git_templates if git_available?
        end

        def template_options
          {
            app_name:             app_name,
            upcase_app_name:      upcase_app_name,
            classified_app_name:  classified_app_name,
            application_base_url: application_base_url,
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
          init_git if git_available?
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
          add_mapping('config/application.rb.tt', 'config/application.rb')
          add_mapping('config/routes.rb.tt', 'config/routes.rb')
          add_mapping('views/application_layout.rb.tt', 'app/views/application_layout.rb')
          add_mapping("templates/application.html.#{ template_engine.name }.tt", "app/templates/application.html.#{ template_engine.name }")
          add_mapping('favicon.ico', 'app/assets/favicon.ico')
        end

        def add_test_templates
          if test_framework.rspec?
            add_mapping('Rakefile.rspec.tt', 'Rakefile')
            add_mapping('rspec.rspec.tt', '.rspec')
            add_mapping('spec_helper.rb.rspec.tt', 'spec/spec_helper.rb')
            add_mapping('features_helper.rb.rspec.tt', 'spec/features_helper.rb')
            add_mapping('capybara.rb.rspec.tt', 'spec/support/capybara.rb')
          else
            add_mapping('Rakefile.minitest.tt', 'Rakefile')
            add_mapping('spec_helper.rb.minitest.tt', 'spec/spec_helper.rb')
            add_mapping('features_helper.rb.minitest.tt', 'spec/features_helper.rb')
          end
        end

        def add_empty_directories
          add_mapping('.keep', 'config/initializers/.keep')
          add_mapping('.keep', 'app/controllers/.keep')
          add_mapping('.keep', 'app/views/.keep')
          add_mapping('.keep', 'app/assets/images/.keep')
          add_mapping('.keep', 'app/assets/javascripts/.keep')
          add_mapping('.keep', 'app/assets/stylesheets/.keep')
          add_mapping('.keep', "lib/#{ app_name }/entities/.keep")
          add_mapping('.keep', "lib/#{ app_name }/repositories/.keep")
          add_mapping('.keep', "lib/#{ app_name }/mailers/.keep")
          add_mapping('.keep', "lib/#{ app_name }/mailers/templates/.keep")
          add_mapping('.keep', 'public/.keep')

          add_mapping('.keep', 'spec/features/.keep')
          add_mapping('.keep', 'spec/controllers/.keep')
          add_mapping('.keep', 'spec/views/.keep')
          add_mapping('.keep', "spec/#{ app_name }/entities/.keep")
          add_mapping('.keep', "spec/#{ app_name }/repositories/.keep")
          add_mapping('.keep', "spec/#{ app_name }/mailers/.keep")
          add_mapping('.keep', 'spec/support/.keep')

          if database_config.sql?
            add_mapping('.keep', 'db/migrations/.keep')
          else
            add_mapping('.keep', 'db/.keep')
          end
        end

        def template_source_path
          Pathname.new(::File.dirname(__FILE__)).join('..', '..', 'generators', 'application', 'app').realpath
        end

        def upcase_app_name
          app_name.to_env_s
        end

        def classified_app_name
          Utils::String.new(app_name).classify.tr('::', '')
        end

        alias app_name project_name
      end
    end
  end
end
