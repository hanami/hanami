module Hanami
  module Cli
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
            template           = File.join("apps", app, "templates", controller, "#{action}.html.#{options.fetch(:template)}")
            http_method        = route_http_method(action, options)
            context            = Context.new(app: app, controller: controller, action: action, template: template, test: options.fetch(:test), http_method: http_method, options: options)

            assert_valid_app!(context)
            assert_valid_route_url!(context)
            assert_valid_route_http_method!(context)

            generate_action(context)
            generate_view(context)
            generate_template(context)
            generate_action_spec(context)
            generate_view_spec(context)
            insert_route(context)

            # FIXME this should be removed
            true
          end

          private

          def controller_and_action_name(name)
            # FIXME: extract this regexp
            name.split(/#|\//)
          end

          def assert_valid_app!(context)
            # FIXME: extract these hardcoded values
            apps = Dir.glob(File.join("apps", "*")).map { |app| File.basename(app) }

            return if apps.include?(context.app)
            existing_apps = apps.map { |name| "`#{name}'" }.join(' ')
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
            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app, "controllers", context.controller, "#{context.action}.rb")
            source      = if context.options.fetch(:skip_view, false)
                            File.join(__dir__, "action", "action_without_view.erb")
                          else
                            File.join(__dir__, "action", "action.erb")
                          end

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_view(context)
            return if context.options.fetch(:skip_view, false)

            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app, "views", context.controller, "#{context.action}.rb")
            source      = File.join(__dir__, "action", "view.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_template(context)
            return if context.options.fetch(:skip_view, false)

            # FIXME: extract these hardcoded values
            destination = context.template

            files.touch(destination)
            say(:create, destination)
          end

          def generate_action_spec(context)
            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.app, "controllers", context.controller, "#{context.action}_spec.rb")
            source      = File.join(__dir__, "action", "action_spec.#{context.test}.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def generate_view_spec(context)
            return if context.options.fetch(:skip_view, false)

            # FIXME: extract these hardcoded values
            destination = File.join("spec", context.app, "views", context.controller, "#{context.action}_spec.rb")
            source      = File.join(__dir__, "action", "view_spec.#{context.test}.erb")

            generate_file(source, destination, context)
            say(:create, destination)
          end

          def insert_route(context)
            # FIXME: extract these hardcoded values
            destination = File.join("apps", context.app, "config", "routes.rb")
            content     = "#{context.http_method} '#{route_url(context)}', to: '#{route_endpoint(context)}'".downcase

            files.append(destination, content)
            say(:insert, destination)
          end

          def route_http_method(action, options)
            options.fetch(:method) { route_resourceful_http_method(action) }
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
