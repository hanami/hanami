module Hanami
  class CLI
    module Commands
      module Generate
        # @since 1.1.0
        # @api private
        class Action < Command
          requires "environment"

          desc "Generate an action for app"

          example [
            "web home#index                    # Basic usage",
            "admin home#index                  # Generate for `admin` app",
            "web home#index --url=/            # Specify URL",
            "web sessions#destroy --method=GET # Specify HTTP method",
            "web books#create --skip-view      # Skip view and template"
          ]

          argument :app,    required: true, desc: "The application name (eg. `web`)"
          argument :action, required: true, desc: "The action name (eg. `home#index`)"

          option :url, desc: "The action URL"
          option :method, desc: "The action HTTP method"
          option :skip_view, type: :boolean, default: false, desc: "Skip view and template"

          # @since 1.1.0
          # @api private
          #
          # rubocop:disable Metrics/AbcSize
          # rubocop:disable Metrics/MethodLength
          def call(app:, action:, **options)
            *controller, action        = controller_and_action_name(action)
            classified_controller_name = classified_controller(controller)
            http_method                = route_http_method(action, options)
            context                    = Context.new(app: app, controller: controller, classified_controller_name: classified_controller_name, action: action, test: options.fetch(:test), http_method: http_method, options: options)
            context                    = context.with(template: project.template(context))

            assert_valid_app!(context)
            assert_valid_route_url!(context)
            assert_valid_route_http_method!(context)

            generate_action(context)
            generate_view(context)
            generate_template(context)
            generate_action_spec(context)
            generate_view_spec(context)
            insert_route(context)
          end
          # rubocop:enable Metrics/MethodLength
          # rubocop:enable Metrics/AbcSize

          private

          # @since 1.1.0
          # @api private
          def controller_and_action_name(name)
            # FIXME: extract this regexp
            name.split(/#|\//)
          end

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
          def assert_valid_route_url!(context)
            if context.options.key?(:url) && Utils::Blank.blank?(context.options[:url]) # rubocop:disable Style/GuardClause
              warn "`#{context.options[:url]}' is not a valid URL"
              exit(1)
            end
          end

          # @since 1.1.0
          # @api private
          def assert_valid_route_http_method!(context)
            unless Hanami::Routing::Route::VALID_HTTP_VERBS.include?(context.http_method.upcase) # rubocop:disable Style/GuardClause
              warn "`#{context.http_method.upcase}' is not a valid HTTP method. Please use one of: #{Hanami::Routing::Route::VALID_HTTP_VERBS.map { |verb| "`#{verb}'" }.join(' ')}"
              exit(1)
            end
          end

          # @since 1.1.0
          # @api private
          def generate_action(context)
            source      = if skip_view?(context)
                            templates.find("action_without_view.erb")
                          else
                            templates.find("action.erb")
                          end
            destination = project.action(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          # @since 1.1.0
          # @api private
          def generate_view(context)
            return if skip_view?(context)

            source      = templates.find("view.erb")
            destination = project.view(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          # @since 1.1.0
          # @api private
          def generate_template(context)
            return if skip_view?(context)
            destination = project.template(context)

            files.touch(destination)
            say(:create, destination)
          end

          # @since 1.1.0
          # @api private
          def generate_action_spec(context)
            source      = templates.find("action_spec.#{context.test}.erb")
            destination = project.action_spec(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          # @since 1.1.0
          # @api private
          def generate_view_spec(context)
            return if skip_view?(context)

            source      = templates.find("view_spec.#{context.test}.erb")
            destination = project.view_spec(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          # @since 1.1.0
          # @api private
          def insert_route(context)
            content     = "#{context.http_method} '#{route_url(context)}', to: '#{route_endpoint(context)}'".downcase
            destination = project.app_routes(context)

            files.append(destination, content)
            say(:insert, destination)
          end

          # @since 1.1.0
          # @api private
          def route_http_method(action, options)
            options.fetch(:method) { route_resourceful_http_method(action) }
          end

          # @since 1.1.0
          # @api private
          def skip_view?(context)
            context.options.fetch(:skip_view, false)
          end

          # @since 1.1.0
          # @api private
          DEFAULT_HTTP_METHOD = 'GET'.freeze

          # @since 1.1.0
          # @api private
          RESOURCEFUL_HTTP_METHODS = {
            'create'  => 'POST',
            'update'  => 'PATCH',
            'destroy' => 'DELETE'
          }.freeze

          # @since 1.1.0
          # @api private
          def route_resourceful_http_method(action)
            RESOURCEFUL_HTTP_METHODS.fetch(action, DEFAULT_HTTP_METHOD)
          end

          # @since 1.1.0
          # @api private
          def route_url(context)
            context.options.fetch(:url) { route_resourceful_url(context) }
          end

          # @since 1.1.0
          # @api private
          def route_resourceful_url(context)
            "/#{namespaced_controller(context)}#{route_resourceful_url_suffix(context)}"
          end

          # @since 1.1.0
          # @api private
          RESOURCEFUL_ROUTE_URL_SUFFIXES = {
            'index'   => '',
            'new'     => '/new',
            'create'  => '',
            'edit'    => '/:id/edit',
            'update'  => '/:id',
            'show'    => '/:id',
            'destroy' => '/:id'
          }.freeze

          # @since 1.1.0
          # @api private
          def route_resourceful_url_suffix(context)
            RESOURCEFUL_ROUTE_URL_SUFFIXES.fetch(context.action) { "/#{context.action}" }
          end

          # @since 1.1.0
          # @api private
          def route_endpoint(context)
            "#{namespaced_controller(context)}##{context.action}"
          end

          # @since 1.1.0
          # @api private
          def classified_controller(controller)
            controller.
              map { |controller_name| Utils::String.new(controller_name).classify }.
              join("::")
          end

          # @since 1.1.0
          # @api private
          def namespaced_controller(context)
            context.controller.join("/")
          end
        end
      end
    end
  end
end
