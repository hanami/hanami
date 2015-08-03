require 'shellwords'
require 'lotus/generators/generator'
require 'lotus/application_name'
require 'lotus/commands/generate/app'
require 'lotus/commands/new/abstract'

module Lotus
  module Commands
    class New < Thor
      class Container < Abstract
        DEFAULT_APPLICATION_NAME = 'web'.freeze

        private

        def start_in_app_dir
          process_templates
          init_git
          Lotus::Commands::Generate::App.new(app_generator_options, app_slice_name).start
        end

        # options that are forwarded to app generator
        def app_generator_options
          {
            application_base_url: application_base_url
          }
        end

        def app_slice_name
          options.fetch(:application_name, DEFAULT_APPLICATION_NAME)
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
        end

        def add_test_templates
          if test_framework.rspec?
            @generator.add_mapping('Rakefile.rspec.tt', 'Rakefile')
            @generator.add_mapping('rspec.rspec.tt', '.rspec')
            @generator.add_mapping('spec_helper.rb.rspec.tt', 'spec/spec_helper.rb')
            @generator.add_mapping('features_helper.rb.rspec.tt', 'spec/features_helper.rb')
            @generator.add_mapping('capybara.rb.rspec.tt', 'spec/support/capybara.rb')
          else # minitest (default)
            @generator.add_mapping('Rakefile.minitest.tt', 'Rakefile')
            @generator.add_mapping('spec_helper.rb.minitest.tt', 'spec/spec_helper.rb')
            @generator.add_mapping('features_helper.rb.minitest.tt', 'spec/features_helper.rb')
          end
        end

        def add_empty_directories
          @generator.add_mapping('.gitkeep', "lib/#{ app_name }/entities/.gitkeep")
          @generator.add_mapping('.gitkeep', "lib/#{ app_name }/repositories/.gitkeep")
          @generator.add_mapping('.gitkeep', "lib/#{ app_name }/mailers/.gitkeep")
          @generator.add_mapping('.gitkeep', "lib/#{ app_name }/mailers/templates/.gitkeep")
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
            lotus_head:            lotus_head?,
            test:                  test_framework.framework,
            database:              database_config.type,
            database_config:       database_config.to_hash,
            lotus_model_version:   lotus_model_version,
          }
        end

        def template_source_path
          Pathname.new(::File.dirname(__FILE__)).join('..', '..', 'generators', 'application', 'container').realpath
        end
      end
    end
  end
end
