require 'hanami/commands/new/abstract'

module Hanami
  # @api private
  module Commands
    # @api private
    class New
      # @api private
      class App < Abstract

        # @api private
        def initialize(options, name)
          super(options, name)
        end

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

        # @api private
        def post_process_templates
          init_git
        end

        private

        # @api private
        def add_application_templates
          add_mapping('hanamirc.tt', '.hanamirc')
          add_mapping('.env.development.tt', '.env.development')
          add_mapping('.env.test.tt', '.env.test')
          add_mapping('README.md.tt', 'README.md')
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

        # @api private
        def add_test_templates
          if test_framework.rspec?
            add_mapping('Rakefile.rspec.tt', 'Rakefile')
            add_mapping('rspec.rspec.tt', '.rspec')
            add_mapping('spec_helper.rb.rspec.tt', 'spec/spec_helper.rb')
            add_mapping('features_helper.rb.rspec.tt', 'spec/features_helper.rb')
            add_mapping('capybara.rb.rspec.tt', 'spec/support/capybara.rb')
            add_mapping("spec/views/application_layout_spec.rb.rspec.tt", "spec/#{ app_name }/views/application_layout_spec.rb")
          else
            add_mapping('Rakefile.minitest.tt', 'Rakefile')
            add_mapping('spec_helper.rb.minitest.tt', 'spec/spec_helper.rb')
            add_mapping('features_helper.rb.minitest.tt', 'spec/features_helper.rb')
            add_mapping("spec/views/application_layout_spec.rb.minitest.tt", "spec/#{ app_name }/views/application_layout_spec.rb")
          end
        end

        # @api private
        def add_empty_directories
          add_mapping('.gitkeep', 'config/initializers/.gitkeep')
          add_mapping('.gitkeep', 'app/controllers/.gitkeep')
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

        # @api private
        def template_source_path
          Pathname.new(::File.dirname(__FILE__)).join('..', '..', 'generators', 'application', 'app').realpath
        end

        # @api private
        def upcase_app_name
          app_name.to_env_s
        end

        # @api private
        def classified_app_name
          Utils::String.new(app_name).classify.tr('::', '')
        end

        # @api private
        alias app_name project_name
      end
    end
  end
end
