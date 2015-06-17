require 'shellwords'
require 'lotus/generators/abstract'

module Lotus
  module Generators
    module Application
      class App < Abstract
        def initialize(command)
          super

          @upcase_app_name       = app_name.to_env_s
          @classified_app_name   = Utils::String.new(app_name).classify
          @lotus_head            = options.fetch(:lotus_head)
          @test                  = options[:test]
          @database              = options[:database]
          @application_base_url  = options[:application_base_url]
          @lotus_model_version   = '~> 0.3'

          cli.class.source_root(source)
        end

        def start

          opts      = {
            app_name:              app_name,
            upcase_app_name:       @upcase_app_name,
            classified_app_name:   @classified_app_name,
            application_base_url:  @application_base_url,
            lotus_head:            @lotus_head,
            test:                  @test,
            database:              @database,
            database_config:       database_config,
            lotus_model_version:   @lotus_model_version,
          }

          templates = {
            'lotusrc.tt'                             => '.lotusrc',
            '.env.tt'                                => '.env',
            '.env.development.tt'                    => '.env.development',
            '.env.test.tt'                           => '.env.test',
            'Gemfile.tt'                             => 'Gemfile',
            'config.ru.tt'                           => 'config.ru',
            'config/environment.rb.tt'               => 'config/environment.rb',
            'lib/app_name.rb.tt'                     => "lib/#{ app_name }.rb",
            'lib/config/mapping.rb.tt'               => 'lib/config/mapping.rb',
            'apps/application.rb.tt'                 => 'apps/application.rb',
            'apps/config/routes.rb.tt'               => 'apps/config/routes.rb',
            'apps/action.rb.tt'                      => 'apps/controllers/home/index.rb',
            'apps/views/application_layout.rb.tt'    => 'apps/views/application_layout.rb',
            'apps/templates/application.html.erb.tt' => 'apps/templates/application.html.erb',
            'apps/view.rb.tt'                        => 'apps/views/home/index.rb',
            'apps/templates/template.html.erb.tt'    => 'apps/templates/home/index.html.erb',
          }

          empty_directories = [
            "db",
            "lib/#{ app_name }/entities",
            "lib/#{ app_name }/repositories",
            "apps/public/javascripts",
            "apps/public/stylesheets"
          ]

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
            "spec/support"
          ]

          templates.each do |src, dst|
            cli.template(source.join(src), target.join(dst), opts)
          end

          empty_directories.flatten.each do |dir|
            gitkeep = '.gitkeep'
            cli.template(source.join(gitkeep), target.join(dir, gitkeep), opts)
          end

          unless git_dir_present?
            cli.template(source.join('gitignore.tt'), target.join('.gitignore'), opts)
            cli.run("git init #{Shellwords.escape(target)}", capture: true)
          end
        end

        private

        def git_dir_present?
          File.directory?(source.join('.git'))
        end

        def database_config
          {
            gem: database_gem,
            uri: database_uri,
            type: database_type
          }
        end

        def database_gem
          {
            'mysql'      => 'mysql',
            'mysql2'     => 'mysql2',
            'postgresql' => 'pg',
            'postgres'   => 'pg',
            'sqlite'     => 'sqlite3',
            'sqlite3'    => 'sqlite3'
          }[@database]
        end

        def database_type
          case @database
          when 'mysql', 'mysql2', 'postgresql', 'postgres', 'sqlite', 'sqlite3'
            :sql
          when 'filesystem'
            :file_system
          when 'memory'
            :memory
          end
        end

        def database_uri
          {
            development: "#{database_base_uri}_development",
            test: "#{database_base_uri}_test"
          }
        end

        def database_base_uri
          case @database
          when 'mysql'
            "mysql://localhost/#{app_name}"
          when 'mysql2'
            "mysql2://localhost/#{app_name}"
          when 'postgresql', 'postgres'
            "postgres://localhost/#{app_name}"
          when 'sqlite', 'sqlite3'
            "sqlite://db/#{Shellwords.escape(app_name)}"
          when 'memory'
            "memory://localhost/#{app_name}"
          else
            "file:///db/#{app_name}"
          end
        end
      end
    end
  end
end
