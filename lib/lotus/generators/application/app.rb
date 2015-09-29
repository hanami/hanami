require 'shellwords'
require 'lotus/generators/abstract'
require 'lotus/generators/database_config'

module Lotus
  module Generators
    module Application
      class App < Abstract
        def initialize(command)
          super

          @upcase_app_name      = app_name.to_env_s
          @classified_app_name  = Utils::String.new(app_name).classify
          @lotus_head           = options.fetch(:lotus_head)
          @test                 = options[:test]
          @database_config      = DatabaseConfig.new(options[:database], app_name)
          @application_base_url = options[:application_base_url]
          @lotus_model_version  = '~> 0.5'

          cli.class.source_root(source)
        end

        def start

          opts      = {
            app_name:             app_name,
            upcase_app_name:      @upcase_app_name,
            classified_app_name:  @classified_app_name,
            application_base_url: @application_base_url,
            lotus_head:           @lotus_head,
            test:                 @test,
            database:             @database_config.engine,
            database_config:      @database_config.to_hash,
            lotus_model_version:  @lotus_model_version,
          }

          templates = {
            'lotusrc.tt'                        => '.lotusrc',
            '.env.tt'                           => '.env',
            '.env.development.tt'               => '.env.development',
            '.env.test.tt'                      => '.env.test',
            'Gemfile.tt'                        => 'Gemfile',
            'config.ru.tt'                      => 'config.ru',
            'config/environment.rb.tt'          => 'config/environment.rb',
            'lib/app_name.rb.tt'                => "lib/#{ app_name }.rb",
            'lib/config/mapping.rb.tt'          => 'lib/config/mapping.rb',
            'config/application.rb.tt'          => 'config/application.rb',
            'config/routes.rb.tt'               => 'config/routes.rb',
            'views/application_layout.rb.tt'    => 'app/views/application_layout.rb',
            'templates/application.html.erb.tt' => 'app/templates/application.html.erb',
          }

          empty_directories = [
            "app/controllers",
            "app/views",
            "lib/#{ app_name }/entities",
            "lib/#{ app_name }/repositories",
            "lib/#{ app_name }/mailers",
            "public/javascripts",
            "public/stylesheets"
          ]

          empty_directories << if @database_config.sql?
            "db/migrations"
          else
            "db"
          end

          # Add testing directories (spec/ is the default for both MiniTest and RSpec)
          empty_directories << [
            "spec/features",
            "spec/controllers",
            "spec/views"
          ]

          case options[:test]
          when 'rspec'
            templates.merge!(
              'Rakefile.rspec.tt'           => 'Rakefile',
              'rspec.rspec.tt'              => '.rspec',
              'spec_helper.rb.rspec.tt'     => 'spec/spec_helper.rb',
              'features_helper.rb.rspec.tt' => 'spec/features_helper.rb',
              'capybara.rb.rspec.tt'        => 'spec/support/capybara.rb'
            )
          else # minitest (default)
            templates.merge!(
              'Rakefile.minitest.tt'           => 'Rakefile',
              'spec_helper.rb.minitest.tt'     => 'spec/spec_helper.rb',
              'features_helper.rb.minitest.tt' => 'spec/features_helper.rb'
            )
          end

          empty_directories << [
            "spec/#{ app_name }/entities",
            "spec/#{ app_name }/repositories",
            "spec/#{ app_name }/mailers",
            "spec/support"
          ]

          if @database_config.sql?
            templates.merge!(
              'schema.sql.tt' => 'db/schema.sql'
            )
          end

          templates.each do |src, dst|
            cli.template(source.join(src), target.join(dst), opts)
          end

          empty_directories.flatten.each do |dir|
            gitkeep = '.gitkeep'
            cli.template(source.join(gitkeep), target.join(dir, gitkeep), opts)
          end

          unless git_dir_present?
            cli.template(source.join(@database_config.type == :file_system ? 'gitignore.tt' : '.gitignore'), target.join('.gitignore'), opts)
            cli.run("git init #{Shellwords.escape(target)}", capture: true)
          end
        end

        private

        def git_dir_present?
          File.directory?(source.join('.git'))
        end
      end
    end
  end
end
