module Hanami
  module Cli
    module Commands
      module Generate
        class App < Command
          requires "environment"
          argument :app, required: true
          option :application_base_url

          def call(app:, application_base_url: nil, **options)
            app      = Utils::String.new(app).underscore
            template = options.fetch(:template)
            base_url = application_base_url || "/#{app}"
            context  = Context.new(app: app, base_url: base_url, test: options.fetch(:test), template: template, options: options)

            assert_valid_base_url!(context)

            generate_app(context)
            generate_routes(context)
            generate_layout(context)
            generate_template(context)
            generate_favicon(context)

            create_controllers_directory(context)
            create_assets_images_directory(context)
            create_assets_javascripts_directory(context)
            create_assets_stylesheets_directory(context)

            create_spec_features_directory(context)
            create_spec_controllers_directory(context)
            generate_layout_spec(context)

            inject_require_app(context)
            inject_mount_app(context)

            append_development_http_session_secret(context)
            append_test_http_session_secret(context)
          end

          private

          def assert_valid_base_url!(context)
            if Utils::Blank.blank?(context.base_url)
              warn "`' is not a valid URL"
              exit(1)
            end
          end

          def generate_app(context)
            source      = templates.find("application.erb")
            destination = project.app_application(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_routes(context)
            source      = templates.find("routes.erb")
            destination = project.app_routes(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_layout(context)
            source      = templates.find("layout.erb")
            destination = project.app_layout(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_template(context)
            source      = templates.find("template.#{context.template}.erb")
            destination = project.app_template(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_favicon(context)
            source      = templates.find("favicon.ico")
            destination = project.app_favicon(context)

            files.cp(source, destination)
            say(:create, destination)
          end

          def create_controllers_directory(context)
            source      = templates.find("gitkeep.erb")
            destination = project.keep(project.controllers(context))

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def create_assets_images_directory(context)
            source      = templates.find("gitkeep.erb")
            destination = project.keep(project.images(context))

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def create_assets_javascripts_directory(context)
            source      = templates.find("gitkeep.erb")
            destination = project.keep(project.javascripts(context))

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def create_assets_stylesheets_directory(context)
            source      = templates.find("gitkeep.erb")
            destination = project.keep(project.stylesheets(context))

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def create_spec_features_directory(context)
            source      = templates.find("gitkeep.erb")
            destination = project.keep(project.features_spec(context))

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def create_spec_controllers_directory(context)
            source      = templates.find("gitkeep.erb")
            destination = project.keep(project.controllers_spec(context))

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_layout_spec(context)
            source      = templates.find("layout_spec.#{context.options.fetch(:test)}.erb")
            destination = project.app_layout_spec(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def inject_require_app(context)
            content     = "require_relative '../apps/#{context.app}/application'"
            destination = project.environment(context)

            files.inject_after(destination, content, /require_relative '\.\.\/lib\/.*'/)
            say(:insert, destination)
          end

          def inject_mount_app(context)
            content     = "  mount #{context.app.classify}::Application, at: '#{context.base_url}'"
            destination = project.environment(context)

            files.inject_after(destination, content, /Hanami.configure do/)
            say(:insert, destination)
          end

          def append_development_http_session_secret(context)
            # FIXME: Unify the secret generation algorithm with `hanami secret` command
            content     = %(#{context.app.upcase}_SESSIONS_SECRET="#{SecureRandom.hex(32)}")
            destination = project.env(context, "development")

            files.append(destination, content)
            say(:append, destination)
          end

          def append_test_http_session_secret(context)
            content     = %(#{context.app.upcase}_SESSIONS_SECRET="#{SecureRandom.hex(32)}")
            destination = project.env(context, "test")

            files.append(destination, content)
            say(:append, destination)
          end
        end
      end
    end
  end
end
