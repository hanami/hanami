module Hanami
  class Cli
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
          end

          private

          def assert_valid_app!(context)
            return if project.app?(context)

            existing_apps = project.apps.map { |name| "`#{name}'" }.join(' ')
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
            content     = %r{#{context.action_name}}
            destination = project.app_routes(context)

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
            destination = project.view_spec(context)
            return unless files.exist?(destination)

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_action_spec(context)
            destination = project.action_spec(context)

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_templates(context)
            destinations = project.templates(context)
            destinations.each do |destination|
              files.delete(destination)
              say(:remove, destination)
            end
          end

          def destroy_view(context)
            destination = project.view(context)
            return unless files.exist?(destination)

            files.delete(destination)
            say(:remove, destination)
          end

          def destroy_action(context)
            destination = project.action(context)

            files.delete(destination)
            say(:remove, destination)
          end
        end
      end
    end
  end
end
