require "hanami/utils/file_list"

module Hanami
  module Cli
    module Commands
      module Destroy
        class Action < Command
          argument :app,    required: true
          argument :action, required: true

          def call(app:, action:, **options)
            app                = Utils::String.new(app).underscore
            controller, action = controller_and_action(action)
            action_name        = controller_and_action_name(controller, action)

            context = Context.new(app: app, controller: controller, action: action, action_name: action_name, options: options)

            assert_valid_app!(context)

            remove_route(context)
            destroy_view_spec(context)
            destroy_action_spec(context)
            destroy_templates(context)
            destroy_view(context)
            destroy_action(context)

            # FIXME this should be removed
            true
          end

          private

          def assert_valid_app!(context)
            # FIXME: extract these hardcoded values
            apps = Dir.glob(File.join("apps", "*")).map { |a| File.basename(a) }

            return if apps.include?(context.app)
            existing_apps = apps.map { |name| "`#{name}'" }.join(' ')
            warn "`#{context.app}' is not a valid APP. Please specify one of: #{existing_apps}"
            exit(1)
          end

          def controller_and_action(name)
            # FIXME: extract this regexp
            name.split(/#|\//)
          end

          def controller_and_action_name(controller, action)
            # FIXME: extract this separator
            [controller, action].join("#")
          end

          def remove_route(context)
            destination = File.join("apps", context.app, "config", "routes.rb")
            content     = %r{#{context.action_name}}

            begin
              files.remove_line(destination, content)
            rescue ArgumentError
              warn "cannot find `#{context.action_name}' in `#{context.app}' application."
              warn "please run `hanami routes' to know the existing actions."
              exit(1)
            end

            say(:subtract, destination)
          end

          def destroy_view_spec(context)
            destination = File.join("spec", context.app, "views", context.controller, "#{context.action}_spec.rb")
            return unless files.exist?(destination)

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_action_spec(context)
            destination = File.join("spec", context.app, "controllers", context.controller, "#{context.action}_spec.rb")

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_templates(context)
            pattern      = File.join("apps", context.app, "templates", context.controller, "#{context.action}.*.*")
            destinations = Hanami::Utils::FileList[pattern]
            destinations.each do |destination|
              files.delete(destination)
              say(:remove, destination)
            end
          end

          def destroy_view(context)
            destination = File.join("apps", context.app, "views", context.controller, "#{context.action}.rb")
            return unless File.exist?(destination)

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_action(context)
            destination = File.join("apps", context.app, "controllers", context.controller, "#{context.action}.rb")

            files.delete(destination)
            say(:remove, destination)
          end
        end
      end
    end
  end
end
