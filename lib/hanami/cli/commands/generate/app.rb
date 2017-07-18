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

            # FIXME this should be removed
            true
          end

          private

          def assert_valid_base_url!(context)
            if Utils::Blank.blank?(context.base_url)
              warn "`' is not a valid URL"
              exit(1)
            end
          end

          def generate_app(context)
            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app, "application.rb")
            source      = File.join(__dir__, "app", "application.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_routes(context)
            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app, "config", "routes.rb")
            source      = File.join(__dir__, "app", "routes.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_layout(context)
            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app, "views", "application_layout.rb")
            source      = File.join(__dir__, "app", "layout.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_template(context)
            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app, "templates", "application.html.#{context.template}")
            source      = File.join(__dir__, "app", "template.#{context.template}.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_favicon(context)
            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app, "assets", "favicon.ico")
            source      = File.join(__dir__, "app", "favicon.ico")

            files.cp(source, destination)
            say(:create, destination)
          end

          def create_controllers_directory(context)
            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app, "controllers", ".gitkeep")
            source      = File.join(__dir__, "app", "gitkeep.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def create_assets_images_directory(context)
            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app, "assets", "images", ".gitkeep")
            source      = File.join(__dir__, "app", "gitkeep.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def create_assets_javascripts_directory(context)
            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app, "assets", "javascripts", ".gitkeep")
            source      = File.join(__dir__, "app", "gitkeep.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def create_assets_stylesheets_directory(context)
            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app, "assets", "stylesheets", ".gitkeep")
            source      = File.join(__dir__, "app", "gitkeep.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def create_spec_features_directory(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.app, "features", ".gitkeep")
            source      = File.join(__dir__, "app", "gitkeep.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def create_spec_controllers_directory(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.app, "controllers", ".gitkeep")
            source      = File.join(__dir__, "app", "gitkeep.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_layout_spec(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.app, "views", "application_layout_spec.rb")
            source      = File.join(__dir__, "app", "layout_spec.#{context.options.fetch(:test)}.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def inject_require_app(context)
            # FIXME: extract these hardcoded values
            destination = File.join("config", "environment.rb")
            content     = "require_relative '../apps/#{context.app}/application'"

            files.inject_after(destination, content, /require_relative '\.\.\/lib\/.*'/)
            say(:insert, destination)
          end

          def inject_mount_app(context)
            destination = File.join("config", "environment.rb")
            content     = "  mount #{context.app.classify}::Application, at: '#{context.base_url}'"

            files.inject_after(destination, content, /Hanami.configure do/)
            say(:insert, destination)
          end

          def append_development_http_session_secret(context)
            # FIXME: Unify the secret generation algorithm with `hanami secret` command
            destination = File.join(".env.development")
            content     = %(#{context.app.upcase}_SESSIONS_SECRET="#{SecureRandom.hex(32)}")

            files.append(destination, content)
            say(:append, destination)
          end

          def append_test_http_session_secret(context)
            # FIXME: Unify the secret generation algorithm with `hanami secret` command
            destination = File.join(".env.test")
            content     = %(#{context.app.upcase}_SESSIONS_SECRET="#{SecureRandom.hex(32)}")

            files.append(destination, content)
            say(:append, destination)
          end
        end
      end
    end
  end
end
