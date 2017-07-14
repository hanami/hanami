module Hanami
  module Cli
    module Commands
      # FIXME: this must be a module
      class Destroy
        class App
          include Hanami::Cli::Command
          register "destroy app"

          argument :app, required: true

          def call(app:, **options)
            # TODO: extract this operation into a mixin
            options = Hanami.environment.to_options.merge(options)

            app = Utils::String.new(app).underscore
            assert_valid_app!(app)

            context = Context.new(app: app, base_url: base_url(app), options: options)

            remove_test_http_session_secret(context)
            remove_development_http_session_secret(context)

            remove_mount_app(context)
            remove_require_app(context)

            recursively_destroy_precompiled_assets(context)
            destroy_assets_manifest(context)

            recursively_destroy_specs(context)
            recursively_destroy_app(context)

            # FIXME this should be removed
            true
          end

          private

          def assert_valid_app!(app)
            # FIXME: extract these hardcoded values
            apps = Dir.glob(File.join("apps", "*")).map { |a| File.basename(a) }

            return if apps.include?(app)
            existing_apps = apps.map { |name| "`#{name}'" }.join(' ')
            warn "`#{app}' is not a valid APP. Please specify one of: #{existing_apps}"
            exit(1)
          end

          def remove_test_http_session_secret(context)
            destination = File.join(".env.test")
            content     = "#{context.app.upcase}_SESSIONS_SECRET"

            remove_line(destination, content)

            say(:subtract, destination)
          end

          def remove_development_http_session_secret(context)
            destination = File.join(".env.development")
            content     = "#{context.app.upcase}_SESSIONS_SECRET"

            remove_line(destination, content)

            say(:subtract, destination)
          end

          def remove_mount_app(context)
            destination = File.join("config", "environment.rb")
            content     = "mount #{context.app.classify}::Application"

            remove_line(destination, content)

            say(:subtract, destination)
          end

          def remove_require_app(context)
            # FIXME: extract these hardcoded values
            destination = File.join("config", "environment.rb")
            content     = "require_relative '../apps/#{context.app}/application'"

            remove_line(destination, content)

            say(:subtract, destination)
          end

          def recursively_destroy_precompiled_assets(context)
            # FIXME: extract this URL to path conversion into Hanami::Utils
            assets_directory = context.base_url.sub(/\A\//, "").split("/")
            # FIXME: extract these hardcoded values
            destination = File.join("public", "assets", *assets_directory)
            return unless File.directory?(destination)

            FileUtils.remove_entry_secure(destination)

            say(:remove, destination)
          end

          def destroy_assets_manifest(context)
            # FIXME: extract these hardcoded values
            destination = File.join("public", "assets.json")
            return unless File.exist?(destination)

            FileUtils.rm(destination)

            say(:remove, destination)
          end

          def recursively_destroy_specs(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.app)

            FileUtils.remove_entry_secure(destination)

            say(:remove, destination)
          end

          def recursively_destroy_app(context)
            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app)

            FileUtils.remove_entry_secure(destination)

            say(:remove, destination)
          end

          def base_url(app)
            destination = File.join("config", "environment.rb")
            content     = "mount #{app.classify}::Application"

            line  = read_matching_line(destination, content)
            *, at = line.split(/at\:[[:space:]]*/)

            at.strip.gsub(/["']*/, "")
          end

          FORMATTER = "%<operation>12s  %<path>s\n".freeze

          def say(operation, path)
            puts(FORMATTER % { operation: operation, path: path })
          end

          def remove_line(path, contents)
            content = ::File.readlines(path)
            i       = index(content, path, contents)

            content.delete_at(i)
            rewrite(path, content)
          end

          def read_matching_line(path, target)
            content = ::File.readlines(path)
            line    = content.find do |l|
              case target
              when String
                l.include?(target)
              when Regexp
                l =~ target
              end
            end

            line or raise ArgumentError.new("Cannot find `#{target}' inside `#{path}'.")
          end

          def rewrite(path, *content)
            open(path, ::File::TRUNC | ::File::WRONLY, *content)
          end

          def open(path, mode, *content)
            ::File.open(path, mode) do |file|
              file.write(Array(content).flatten.join)
            end
          end

          def index(content, path, target)
            line_number(content, target) or
              raise ArgumentError.new("Cannot find `#{target}' inside `#{path}'.")
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
end
