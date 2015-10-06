require 'lotus/commands/generate/abstract'
require 'lotus/generators/generator'
require 'lotus/utils/string'
require 'lotus/application_name'
require 'securerandom'

module Lotus
  module Commands
    class Generate
      class App < Abstract

        def initialize(options, application_name)
          super(options)

          assert_application_name!(application_name)
          assert_architecture!

          @application_name = ApplicationName.new(application_name)

          @generator = Lotus::Generators::Generator.new(template_source_path, target_path)
        end

        def start
          add_require_app
          add_mount_app
          add_web_session_secret
          process_templates
        end

        private

        def application_base_url
          options.fetch(:application_base_url, "/#{app_name}")
        end

        def add_require_app
          # Add "require_relative '../apps/web/application'"
          @generator.inject_into_file base_path.join('config/environment.rb'), after: /require_relative '\.\.\/lib\/(.*)'/ do
            "\nrequire_relative '../apps/#{ app_name }/application'"
          end
        end

        def add_mount_app
          @generator.inject_into_file base_path.join('config/environment.rb'), after: /Lotus::Container.configure do/ do |match|
            "\n  mount #{ classified_app_name }::Application, at: '#{ application_base_url }'"
          end
        end

        def add_web_session_secret
          ['development', 'test'].each do |environment|
            # Add WEB_SESSIONS_SECRET="abc123" (random hex)
            @generator.append_to_file base_path.join(".env.#{ environment }") do
              %(#{ upcase_app_name }_SESSIONS_SECRET="#{ SecureRandom.hex(32) }"\n)
            end
          end
        end

        def target_path
          base_path.join('apps', @application_name.to_s)
        end

        def app_name
          @application_name.to_s
        end

        def upcase_app_name
          @application_name.to_env_s
        end

        def classified_app_name
          Utils::String.new(app_name).classify
        end

        def process_templates
          @generator.add_mapping('application.rb.tt', 'application.rb')
          @generator.add_mapping('config/routes.rb.tt', 'config/routes.rb')
          @generator.add_mapping('views/application_layout.rb.tt', 'views/application_layout.rb')
          @generator.add_mapping('templates/application.html.erb.tt', 'templates/application.html.erb')

          @generator.add_mapping('.gitkeep', 'controllers/.gitkeep')
          @generator.add_mapping('.gitkeep', 'public/javascripts/.gitkeep')
          @generator.add_mapping('.gitkeep', 'public/stylesheets/.gitkeep')
          @generator.add_mapping('.gitkeep', "../../spec/#{ app_name }/features/.gitkeep")
          @generator.add_mapping('.gitkeep', "../../spec/#{ app_name }/controllers/.gitkeep")
          @generator.add_mapping('.gitkeep', "../../spec/#{ app_name }/views/.gitkeep")


          @generator.process_templates(template_options)
        end

        def template_options
          {
            app_name:            app_name,
            upcase_app_name:     upcase_app_name,
            classified_app_name: classified_app_name,
            app_base_url:        application_base_url
          }
        end

        def assert_application_name!(value)
          if value.nil? || value.strip.empty?
            raise ArgumentError.new('Application name is nil or empty')
          end
        end

        def assert_architecture!
          if !environment.container?
            raise ArgumentError.new('App generator is only available for container architecture.')
          end
        end
      end
    end
  end
end
