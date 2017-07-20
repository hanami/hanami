module Hanami
  class Cli
    module Commands
      module Generate
        class Action < Command
          requires "environment"

          argument :app,    required: true
          argument :action, required: true
          option :url
          option :method
          option :skip_view, type: :boolean, default: false

          def call(app:, action:, **options)
            controller, action = controller_and_action_name(action)
            http_method        = route_http_method(action, options)
            context            = Context.new(app: app, controller: controller, action: action, test: options.fetch(:test), http_method: http_method, options: options)
            context            = context.with(template: project.template(context))

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

          private

          def controller_and_action_name(name)
            # FIXME: extract this regexp
            name.split(/#|\//)
          end

          def assert_valid_app!(context)
            return if project.app?(context)

            existing_apps = project.apps.map { |name| "`#{name}'" }.join(' ')
            warn "`#{context.app}' is not a valid APP. Please specify one of: #{existing_apps}"
            exit(1)
          end

          def assert_valid_route_url!(context)
            if context.options.key?(:url) && Utils::Blank.blank?(context.options[:url])
              warn "`#{context.options[:url]}' is not a valid URL"
              exit(1)
            end
          end

          def assert_valid_route_http_method!(context)
            if !Hanami::Routing::Route::VALID_HTTP_VERBS.include?(context.http_method.upcase)
              warn "`#{context.http_method.upcase}' is not a valid HTTP method. Please use one of: #{Hanami::Routing::Route::VALID_HTTP_VERBS.map { |verb| "`#{verb}'" }.join(" ")}"
              exit(1)
            end
          end

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

          def generate_view(context)
            return if skip_view?(context)

            source      = templates.find("view.erb")
            destination = project.view(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_template(context)
            return if skip_view?(context)
            destination = project.template(context)

            files.touch(destination)
            say(:create, destination)
          end

          def generate_action_spec(context)
            source      = templates.find("action_spec.#{context.test}.erb")
            destination = project.action_spec(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_view_spec(context)
            return if skip_view?(context)

            source      = templates.find("view_spec.#{context.test}.erb")
            destination = project.view_spec(context)

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def insert_route(context)
            content     = "#{context.http_method} '#{route_url(context)}', to: '#{route_endpoint(context)}'".downcase
            destination = project.app_routes(context)

            files.append(destination, content)
            say(:insert, destination)
          end

          def route_http_method(action, options)
            options.fetch(:method) { route_resourceful_http_method(action) }
          end

          def skip_view?(context)
            context.options.fetch(:skip_view, false)
          end

          DEFAULT_HTTP_METHOD = 'GET'.freeze

          # HTTP methods used when generating resourceful actions.
          #
          # @since 0.6.0
          # @api private
          RESOURCEFUL_HTTP_METHODS = {
            'create'  => 'POST',
            'update'  => 'PATCH',
            'destroy' => 'DELETE'
          }.freeze

          def route_resourceful_http_method(action)
            RESOURCEFUL_HTTP_METHODS.fetch(action, DEFAULT_HTTP_METHOD)
          end

          def route_url(context)
            context.options.fetch(:url) { route_resourceful_url(context) }
          end

          def route_resourceful_url(context)
            "/#{context.controller}#{route_resourceful_url_suffix(context)}"
          end

          RESOURCEFUL_ROUTE_URL_SUFFIXES = {
            'show'    => '/:id',
            'update'  => '/:id',
            'destroy' => '/:id',
            'new'     => '/new',
            'edit'    => '/:id/edit'
          }.freeze

          def route_resourceful_url_suffix(context)
            RESOURCEFUL_ROUTE_URL_SUFFIXES.fetch(context.action) { "" }
          end

          def route_endpoint(context)
            "#{context.controller}##{context.action}"
          end
        end
      end
    end
  end
end
