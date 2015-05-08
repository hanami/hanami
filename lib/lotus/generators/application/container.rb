require 'shellwords'
require 'lotus/generators/abstract'
require 'lotus/generators/slice'

module Lotus
  module Generators
    module Application
      class Container < Abstract
        def initialize(command)
          super

          @slice_generator       = Slice.new(command)
          @lotus_head            = options.fetch(:lotus_head)
          @test                  = options[:test]
          @database              = options[:database]
          @lotus_model_version   = '~> 0.3'

          cli.class.source_root(source)
        end

        def start

          opts      = {
            app_name:              app_name,
            lotus_head:            @lotus_head,
            test:                  @test,
            database:              @database,
            database_config:       database_config,
            lotus_model_version:   @lotus_model_version,
          }

          templates = {
            'lotusrc.tt'                 => '.lotusrc',
            'Gemfile.tt'                 => 'Gemfile',
            'config.ru.tt'               => 'config.ru',
            'config/environment.rb.tt'   => 'config/environment.rb',
            'config/.env.tt'             => 'config/.env',
            'config/.env.development.tt' => 'config/.env.development',
            'config/.env.test.tt'        => 'config/.env.test',
            'lib/app_name.rb.tt'         => "lib/#{ app_name }.rb",
            'lib/config/mapping.rb.tt'   => 'lib/config/mapping.rb',
          }

          empty_directories = [
            "db",
            "lib/#{ app_name }/entities",
            "lib/#{ app_name }/repositories"
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

          @slice_generator.start
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
