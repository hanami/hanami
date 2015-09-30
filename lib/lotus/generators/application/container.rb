require 'shellwords'
require 'lotus/generators/abstract'
require 'lotus/generators/database_config'
require 'lotus/generators/slice'

module Lotus
  module Generators
    module Application
      class Container < Abstract
        def initialize(command)
          super

          @slice_generator      = Slice.new(command)
          @database_config      = DatabaseConfig.new(options[:database], app_name)
          @lotus_head           = options.fetch(:lotus_head)
          @test                 = options[:test]
          @lotus_model_version  = '~> 0.5'

          cli.class.source_root(source)
        end

        def start
          opts      = {
            app_name:             app_name,
            lotus_head:           @lotus_head,
            test:                 @test,
            database:             @database_config.engine,
            database_config:      @database_config.to_hash,
            lotus_model_version:  @lotus_model_version,
          }

          templates = {
            'lotusrc.tt'               => '.lotusrc',
            '.env.tt'                  => '.env',
            '.env.development.tt'      => '.env.development',
            '.env.test.tt'             => '.env.test',
            'Gemfile.tt'               => 'Gemfile',
            'config.ru.tt'             => 'config.ru',
            'config/environment.rb.tt' => 'config/environment.rb',
            'config/loader.rb.tt'      => 'config/loader.rb',
            'lib/app_name.rb.tt'       => "lib/#{ app_name }.rb",
            'lib/config/mapping.rb.tt' => 'lib/config/mapping.rb',
          }

          empty_directories = [
            "lib/#{ app_name }/entities",
            "lib/#{ app_name }/repositories",
            "lib/#{ app_name }/mailers",
            "lib/#{ app_name }/mailers/templates"
          ]

          empty_directories << if @database_config.sql?
            "db/migrations"
          else
            "db"
          end

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

          if @database_config.sql?
            templates.merge!(
              'schema.sql.tt' => 'db/schema.sql'
            )
          end

          empty_directories << [
            "spec/#{ app_name }/entities",
            "spec/#{ app_name }/repositories",
            "spec/#{ app_name }/mailers",
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
            cli.template(source.join(@database_config.type == :file_system ? 'gitignore.tt' : '.gitignore'), target.join('.gitignore'), opts)
            cli.run("git init #{Shellwords.escape(target)}", capture: true)
          end

          @slice_generator.start
        end

        private

        def git_dir_present?
          File.directory?(source.join('.git'))
        end
      end
    end
  end
end
