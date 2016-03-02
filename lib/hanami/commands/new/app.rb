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
          add_git_templates
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
          init_git
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
          add_mapping('.gitkeep', 'config/initializers/.gitkeep')
          add_mapping('.gitkeep', 'app/controllers/.gitkeep')
          add_mapping('.gitkeep', 'app/views/.gitkeep')
          add_mapping('.gitkeep', 'app/assets/images/.gitkeep')
          add_mapping('.gitkeep', 'app/assets/javascripts/.gitkeep')
          add_mapping('.gitkeep', 'app/assets/stylesheets/.gitkeep')
          add_mapping('.gitkeep', "lib/#{ app_name }/entities/.gitkeep")
          add_mapping('.gitkeep', "lib/#{ app_name }/repositories/.gitkeep")
          add_mapping('.gitkeep', "lib/#{ app_name }/mailers/.gitkeep")
          add_mapping('.gitkeep', "lib/#{ app_name }/mailers/templates/.gitkeep")
          add_mapping('.gitkeep', 'public/.gitkeep')

          add_mapping('.gitkeep', 'spec/features/.gitkeep')
          add_mapping('.gitkeep', 'spec/controllers/.gitkeep')
          add_mapping('.gitkeep', 'spec/views/.gitkeep')
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
        def template_source_path
          Pathname.new(::File.dirname(__FILE__)).join('..', '..', 'generators', 'application', 'app').realpath
        end

        def upcase_app_name
          app_name.to_env_s
        end

        def classified_app_name
          Utils::String.new(app_name).classify.tr('::', '')
        end

        # def application_base_path
        #   [ 'apps', app_name ].join(::File::SEPARATOR)
        # end
      end
    end
  end
end
