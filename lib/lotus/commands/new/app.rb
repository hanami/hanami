require 'shellwords'
require 'lotus/generators/generator'
require 'lotus/application_name'
require 'lotus/commands/generate/app'
require 'lotus/commands/new/abstract'

module Lotus
  module Commands
    class New < Thor
      class App < Abstract

        def initialize(options, name)
          super(options, name)
          assert_no_application_name!
        end
        private

        def start_in_app_dir
          process_templates
          init_git
        end

        def process_templates
          add_application_templates
          add_empty_directories
          add_test_templates
          add_sql_templates
          add_git_templates
          @generator.process_templates(template_options)
        end

        def add_application_templates
          @generator.add_mapping('lotusrc.tt', '.lotusrc')
          @generator.add_mapping('.env.tt', '.env')
          @generator.add_mapping('.env.development.tt', '.env.development')
          @generator.add_mapping('.env.test.tt', '.env.test')
          @generator.add_mapping('Gemfile.tt', 'Gemfile')
          @generator.add_mapping('config.ru.tt', 'config.ru')
          @generator.add_mapping('config/environment.rb.tt', 'config/environment.rb')
          @generator.add_mapping('lib/app_name.rb.tt', "lib/#{ app_name }.rb")
          @generator.add_mapping('lib/config/mapping.rb.tt', 'lib/config/mapping.rb')
          @generator.add_mapping('config/application.rb.tt', 'config/application.rb')
          @generator.add_mapping('config/routes.rb.tt', 'config/routes.rb')
          @generator.add_mapping('views/application_layout.rb.tt', 'app/views/application_layout.rb')
          @generator.add_mapping('templates/application.html.erb.tt', 'app/templates/application.html.erb')
        end

        def add_test_templates
          if test_framework.rspec?
            @generator.add_mapping('Rakefile.rspec.tt', 'Rakefile')
            @generator.add_mapping('rspec.rspec.tt', '.rspec')
            @generator.add_mapping('spec_helper.rb.rspec.tt', 'spec/spec_helper.rb')
            @generator.add_mapping('features_helper.rb.rspec.tt', 'spec/features_helper.rb')
            @generator.add_mapping('capybara.rb.rspec.tt', 'spec/support/capybara.rb')
          else
            @generator.add_mapping('Rakefile.minitest.tt', 'Rakefile')
            @generator.add_mapping('spec_helper.rb.minitest.tt', 'spec/spec_helper.rb')
            @generator.add_mapping('features_helper.rb.minitest.tt', 'spec/features_helper.rb')
          end
        end

        def add_empty_directories
          @generator.add_mapping('.gitkeep', 'app/controllers/.gitkeep')
          @generator.add_mapping('.gitkeep', 'app/views/.gitkeep')
          @generator.add_mapping('.gitkeep', "lib/#{ app_name }/entities/.gitkeep")
          @generator.add_mapping('.gitkeep', "lib/#{ app_name }/repositories/.gitkeep")
          @generator.add_mapping('.gitkeep', "lib/#{ app_name }/mailers/.gitkeep")
          @generator.add_mapping('.gitkeep', "lib/#{ app_name }/mailers/templates/.gitkeep")
          @generator.add_mapping('.gitkeep', 'public/javascripts/.gitkeep')
          @generator.add_mapping('.gitkeep', 'public/stylesheets/.gitkeep')

          @generator.add_mapping('.gitkeep', 'spec/features/.gitkeep')
          @generator.add_mapping('.gitkeep', 'spec/controllers/.gitkeep')
          @generator.add_mapping('.gitkeep', 'spec/views/.gitkeep')
          @generator.add_mapping('.gitkeep', "spec/#{ app_name }/entities/.gitkeep")
          @generator.add_mapping('.gitkeep', "spec/#{ app_name }/repositories/.gitkeep")
          @generator.add_mapping('.gitkeep', "spec/#{ app_name }/mailers/.gitkeep")
          @generator.add_mapping('.gitkeep', 'spec/support/.gitkeep')

          if database_config.sql?
            @generator.add_mapping('.gitkeep', 'db/migrations/.gitkeep')
          else
            @generator.add_mapping('.gitkeep', 'db/.gitkeep')
          end
        end

        def template_options
          {
            app_name:              app_name,
            upcase_app_name:       upcase_app_name,
            classified_app_name:   classified_app_name,
            application_base_url:  application_base_url,
            lotus_head:            lotus_head?,
            test:                  test_framework.framework,
            database:              database_config.type,
            database_config:       database_config.to_hash,
            lotus_model_version:   lotus_model_version,
          }
        end

        def template_source_path
          Pathname.new(::File.dirname(__FILE__)).join('..', '..', 'generators', 'application', 'app').realpath
        end

        def upcase_app_name
          app_name.to_env_s
        end

        def classified_app_name
          Utils::String.new(app_name).classify
        end

        def assert_no_application_name!
          if options.key?(:application_name)
            puts "'application_name' is only supported by container architecture but has been set with a value of '#{options[:application_name]}'. Option will be ignored."
          end
        end

      end
    end
  end
end
