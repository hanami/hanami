module Hanami
  module CommandLine
    # FIXME: this must be a module
    class Generate
      class App
        include Hanami::Cli::Command
        register "generate app"

        argument :app, required: true
        option :application_base_url

        def call(app:, application_base_url: nil, **options)
          # TODO: extract this operation into a mixin
          options = Hanami.environment.to_options.merge(options)

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
          template    = File.join(__dir__, "app", "application.erb")
          template    = File.read(template)

          renderer = Renderer.new
          output   = renderer.call(template, context.binding)

          FileUtils.mkpath(File.dirname(destination))
          File.open(destination, "wb") { |f| f.write(output) }

          say(:create, destination)
        end

        def generate_routes(context)
          # FIXME: extract these hardcoded values
          destination = File.join("apps", context.app, "config", "routes.rb")
          template    = File.join(__dir__, "app", "routes.erb")
          template    = File.read(template)

          renderer = Renderer.new
          output   = renderer.call(template, context.binding)

          FileUtils.mkpath(File.dirname(destination))
          File.open(destination, "wb") { |f| f.write(output) }

          say(:create, destination)
        end

        def generate_layout(context)
          # FIXME: extract these hardcoded values
          destination = File.join("apps", context.app, "views", "application_layout.rb")
          template    = File.join(__dir__, "app", "layout.erb")
          template    = File.read(template)

          renderer = Renderer.new
          output   = renderer.call(template, context.binding)

          FileUtils.mkpath(File.dirname(destination))
          File.open(destination, "wb") { |f| f.write(output) }

          say(:create, destination)
        end

        def generate_template(context)
          # FIXME: extract these hardcoded values
          destination = File.join("apps", context.app, "templates", "application.html.#{context.template}")
          template    = File.join(__dir__, "app", "template.#{context.template}.erb")
          template    = File.read(template)

          renderer = Renderer.new
          output   = renderer.call(template, context.binding)

          FileUtils.mkpath(File.dirname(destination))
          File.open(destination, "wb") { |f| f.write(output) }

          say(:create, destination)
        end

        def generate_favicon(context)
          # FIXME: extract these hardcoded values
          destination = File.join("apps", context.app, "assets", "favicon.ico")
          template    = File.join(__dir__, "app", "favicon.ico")

          FileUtils.mkpath(File.dirname(destination))
          FileUtils.cp(template, destination)

          say(:create, destination)
        end

        def create_controllers_directory(context)
          # FIXME: extract these hardcoded values
          destination = File.join("apps", context.app, "controllers", ".gitkeep")
          template    = File.join(__dir__, "app", "gitkeep.erb")
          template    = File.read(template)

          renderer = Renderer.new
          output   = renderer.call(template, context.binding)

          FileUtils.mkpath(File.dirname(destination))
          File.open(destination, "wb") { |f| f.write(output) }

          say(:create, destination)
        end

        def create_assets_images_directory(context)
          # FIXME: extract these hardcoded values
          destination = File.join("apps", context.app, "assets", "images", ".gitkeep")
          template    = File.join(__dir__, "app", "gitkeep.erb")
          template    = File.read(template)

          renderer = Renderer.new
          output   = renderer.call(template, context.binding)

          FileUtils.mkpath(File.dirname(destination))
          File.open(destination, "wb") { |f| f.write(output) }

          say(:create, destination)
        end

        def create_assets_javascripts_directory(context)
          # FIXME: extract these hardcoded values
          destination = File.join("apps", context.app, "assets", "javascripts", ".gitkeep")
          template    = File.join(__dir__, "app", "gitkeep.erb")
          template    = File.read(template)

          renderer = Renderer.new
          output   = renderer.call(template, context.binding)

          FileUtils.mkpath(File.dirname(destination))
          File.open(destination, "wb") { |f| f.write(output) }

          say(:create, destination)
        end

        def create_assets_stylesheets_directory(context)
          # FIXME: extract these hardcoded values
          destination = File.join("apps", context.app, "assets", "stylesheets", ".gitkeep")
          template    = File.join(__dir__, "app", "gitkeep.erb")
          template    = File.read(template)

          renderer = Renderer.new
          output   = renderer.call(template, context.binding)

          FileUtils.mkpath(File.dirname(destination))
          File.open(destination, "wb") { |f| f.write(output) }

          say(:create, destination)
        end

        def create_spec_features_directory(context)
          # FIXME: extract these hardcoded values
          destination = File.join("spec", context.app, "features", ".gitkeep")
          template    = File.join(__dir__, "app", "gitkeep.erb")
          template    = File.read(template)

          renderer = Renderer.new
          output   = renderer.call(template, context.binding)

          FileUtils.mkpath(File.dirname(destination))
          File.open(destination, "wb") { |f| f.write(output) }

          say(:create, destination)
        end

        def create_spec_controllers_directory(context)
          # FIXME: extract these hardcoded values
          destination = File.join("spec", context.app, "controllers", ".gitkeep")
          template    = File.join(__dir__, "app", "gitkeep.erb")
          template    = File.read(template)

          renderer = Renderer.new
          output   = renderer.call(template, context.binding)

          FileUtils.mkpath(File.dirname(destination))
          File.open(destination, "wb") { |f| f.write(output) }

          say(:create, destination)
        end

        def generate_layout_spec(context)
          # FIXME: extract these hardcoded values
          destination = File.join("spec", context.app, "views", "application_layout_spec.rb")
          template    = File.join(__dir__, "app", "layout_spec.#{context.options.fetch(:test)}.erb")
          template    = File.read(template)

          renderer = Renderer.new
          output   = renderer.call(template, context.binding)

          FileUtils.mkpath(File.dirname(destination))
          File.open(destination, "wb") { |f| f.write(output) }

          say(:create, destination)
        end

        def inject_require_app(context)
          # FIXME: extract these hardcoded values
          destination = File.join("config", "environment.rb")
          content     = "require_relative '../apps/#{context.app}/application'"

          inject_after(destination, content, /require_relative '\.\.\/lib\/.*'/)

          say(:insert, destination)
        end

        def inject_mount_app(context)
          destination = File.join("config", "environment.rb")
          content     = "  mount #{context.app.classify}::Application, at: '#{context.base_url}'"

          inject_after(destination, content, /Hanami.configure do/)

          say(:insert, destination)
        end

        def append_development_http_session_secret(context)
          # FIXME: Unify the secret generation algorithm with `hanami secret` command
          destination = File.join(".env.development")
          content     = %(#{context.app.upcase}_SESSIONS_SECRET="#{SecureRandom.hex(32)}")

          append(destination, content)

          say(:append, destination)
        end

        def append_test_http_session_secret(context)
          # FIXME: Unify the secret generation algorithm with `hanami secret` command
          destination = File.join(".env.test")
          content     = %(#{context.app.upcase}_SESSIONS_SECRET="#{SecureRandom.hex(32)}")

          append(destination, content)

          say(:append, destination)
        end

        FORMATTER = "%<operation>12s  %<path>s\n".freeze

        def say(operation, path)
          puts(FORMATTER % { operation: operation, path: path })
        end

        def inject_after(path, contents, after)
          content = ::File.readlines(path)
          i       = index(content, path, after)

          content.insert(i + 1, "#{contents}\n")
          rewrite(path, content)
        end

        def index(content, path, target)
          line_number(content, target) or
            raise ArgumentError.new("Cannot find `#{target}' inside `#{path}'.")
        end

        def rewrite(path, *content)
          open(path, ::File::TRUNC | ::File::WRONLY, *content)
        end

        def append(path, contents)
          content = ::File.readlines(path)
          content << "#{contents}\n"

          rewrite(path, content)
        end

        def open(path, mode, *content)
          ::File.open(path, mode) do |file|
            file.write(Array(content).flatten.join)
          end
        end

        def line_number(content, target)
          content.index do |l|
            case target
            when String
              l.include?(target)
            when Regexp
              l =~ target
            end
          end
        end
      end
    end
  end
end
