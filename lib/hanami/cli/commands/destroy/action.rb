module Hanami
  class CLI
    module Commands
      module Destroy
        # @since 1.1.0
        # @api private
        class Action < Command
          desc "Destroy an action from app"

          example [
            "web home#index    # Basic usage",
            "admin users#index # Destroy from `admin` app"
          ]

          argument :app,    required: true, desc: "The application name (eg. `web`)"
          argument :action, required: true, desc: "The action name (eg. `home#index`)"

          # @since 1.1.0
          # @api private
          def call(app:, action:, **options)
            app                = Utils::String.underscore(app)
            *controller, action = controller_and_action(action)
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

          # @since 1.1.0
          # @api private
          def assert_valid_app!(context)
            return if project.app?(context)

            existing_apps = project.apps.map { |name| "`#{name}'" }.join(' ')
            warn "`#{context.app}' is not a valid APP. Please specify one of: #{existing_apps}"
            exit(1)
          end

          # @since 1.1.0
          # @api private
          def controller_and_action(name)
            # FIXME: extract this regexp
            name.split(/#|\//)
          end

          # @since 1.1.0
          # @api private
          def controller_and_action_name(controller, action)
            # FIXME: extract this separator
            [namespaced_controller(controller), action].join("#")
          end

          # @since 1.1.0
          # #api private
          def namespaced_controller(controller)
            controller.join("/")
          end

          # @since 1.1.0
          # @api private
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

          # @since 1.1.0
          # @api private
          def destroy_view_spec(context)
            path = project.view_spec(context)

            generator.delete(path, allow_missing: true)
          end

          # @since 1.1.0
          # @api private
          def destroy_action_spec(context)
            path = project.action_spec(context)

            generator.delete(path)
          end

          # @since 1.1.0
          # @api private
          def destroy_templates(context)
            template_paths = project.templates(context)
            template_paths.each do |template_path|
              generator.delete(template_path)
            end
          end

          # @since 1.1.0
          # @api private
          def destroy_view(context)
            path = project.view(context)

            generator.delete(path, allow_missing: true)
          end

          # @since 1.1.0
          # @api private
          def destroy_action(context)
            path = project.action(context)

            generator.delete(path)
          end
        end
      end
    end
  end
end
