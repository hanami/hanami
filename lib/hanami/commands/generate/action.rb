require 'hanami/commands/generate/abstract'
require 'hanami/routing/route'

module Hanami
  module Commands
    class Generate
      class Action < Abstract

        # @since 0.5.0
        # @api private
        ACTION_SEPARATOR = /[\/,#]/

        # @since 0.5.0
        # @api private
        ROUTE_ENDPOINT_SEPARATOR = '#'.freeze

        # @since 0.5.0
        # @api private
        QUOTED_NAME = /(\"|\'|\\)/

        # Default HTTP method used when generating an action.
        #
        # @since 0.5.0
        # @api private
        DEFAULT_HTTP_METHOD = 'GET'.freeze

        # HTTP methods used when generating resourceful actions.
        #
        # @since 0.6.0
        # @api private
        RESOURCEFUL_HTTP_METHODS = {
          'Create'  => 'POST',
          'Update'  => 'PATCH',
          'Destroy' => 'DELETE'
        }.freeze

        # For resourceful actions, what to add to the end of the base URL
        #
        # @since 0.6.0
        # @api private
        RESOURCEFUL_ROUTE_URL_SUFFIXES = {
          'Show'    => '/:id',
          'Update'  => '/:id',
          'Destroy' => '/:id',
          'New'     => '/new',
          'Edit'    => '/:id/edit',
        }.freeze

        def initialize(options, application_name, controller_and_action_name)
          super(options)
          if !environment.container?
            application_name = File.basename(Dir.pwd)
          end

          controller_and_action_name = Utils::String.new(controller_and_action_name).underscore.gsub(QUOTED_NAME, '')

          *controller_name, action_name = controller_and_action_name.split(ACTION_SEPARATOR)

          @application_name = Utils::String.new(application_name).classify
          @controller_name = Utils::String.new(controller_name.join("/")).classify
          @action_name = Utils::String.new(action_name).classify
          @controller_pathname = Utils::String.new(@controller_name).underscore

          assert_application_name!
          assert_controller_name!
          assert_action_name!
          assert_http_method!
        end

        def map_templates
          add_mapping("action_spec.#{test_framework.framework}.tt", action_spec_path)

          if skip_view?
            add_mapping('action_without_view.rb.tt', action_path)
          else
            add_mapping('action.rb.tt', action_path)
            add_mapping('view.rb.tt', view_path)
            add_mapping('template.tt', template_path)
            add_mapping("view_spec.#{test_framework.framework}.tt", view_spec_path)
          end
        end

        def post_process_templates
          generate_route
        end

        # @since 0.5.0
        # @api private
        def template_options
          {
            app:                  @application_name,
            controller:           @controller_name,
            action:               @action_name,
            relative_action_path: relative_action_path,
            relative_view_path:   relative_view_path,
            template_path:        template_path,
          }
        end

        private

        # @since 0.5.0
        # @api private
        def generate_route
          routes_path.dirname.mkpath
          FileUtils.touch(routes_path)

          generator.prepend_to_file(routes_path, "#{ http_method } '#{ route_url }', to: '#{ route_endpoint }'\n")
        end

        def skip_view?
          options.fetch(:skip_view, false)
        end

        # @since 0.5.0
        # @api private
        def http_method
          options.fetch(:method, resourceful_http_method).downcase
        end

        # @since 0.6.0
        # @api private
        def resourceful_http_method
          RESOURCEFUL_HTTP_METHODS.fetch(@action_name, DEFAULT_HTTP_METHOD)
        end

        # @since 0.5.0
        # @api private
        def route_url
          options.fetch(:url, "/#{ @controller_pathname }#{ resourceful_route_url_suffix }")
        end

        # @since 0.6.0
        # @api private
        def resourceful_route_url_suffix
          RESOURCEFUL_ROUTE_URL_SUFFIXES.fetch(@action_name, "")
        end

        # @since 0.5.0
        # @api private
        def route_endpoint
          "#{ @controller_pathname }#{ ROUTE_ENDPOINT_SEPARATOR }#{ @action_name }".downcase
        end

        # @since 0.5.0
        # @api private
        def known_application_names
          Dir.glob(applications_path.join('/*')).map do |name|
            File.basename(name)
          end
        end

        # @since 0.5.0
        # @api private
        def assert_controller_name!
          if @controller_name.nil? || @controller_name.empty?
            raise ArgumentError.new("Unknown controller, please add controllers name with this syntax controller_name#action_name")
          end
        end

        # @since 0.5.0
        # @api private
        def assert_action_name!
          if @action_name.nil? || @action_name.strip == ''
            raise ArgumentError.new("Unknown action, please add actions name with this syntax controller_name#action_name")
          end
        end

        # @since 0.5.0
        # @api private
        def assert_application_name!
          return if !environment.container?
          if @application_name.nil? || @application_name.strip == '' || !application_path.exist?
            existing_apps = known_application_names.join('/')
            raise ArgumentError.new("Unknown app: `#{ @application_name.downcase }'. Please specify one of (#{ existing_apps }) as application name")
          end
        end

        # @since 0.5.0
        # @api private
        def assert_http_method!
          if !Hanami::Routing::Route::VALID_HTTP_VERBS.include?(http_method.upcase)
            existing_http_methods = Hanami::Routing::Route::VALID_HTTP_VERBS
            raise ArgumentError.new("Unknown HTTP method '#{http_method}', please use one of #{ existing_http_methods.join('/') }.")
          end
        end

        def routes_path
          if environment.container?
            application_path.join('config', 'routes.rb')
          else
            application_path.join('..', 'config', 'routes.rb')
          end
        end

        # The directory of the application
        # ./app for 'app' architecture
        # ./apps/APPLICATION_NAME for 'container'
        def application_path
          if environment.container?
            applications_path.join(application_name_as_snake_case)
          else
            Pathname.new('app')
          end
        end

        # The parent dir of the application directory.
        def applications_path
          Pathname.new('apps')
        end

        def view_path
          application_path.join('views', @controller_pathname, "#{@action_name.downcase}.rb")
        end

        def view_spec_path
          spec_root.join('views', @controller_pathname, "#{@action_name.downcase}_spec.rb")
        end

        def template_path
          application_path.join('templates', @controller_pathname, "#{@action_name.downcase}.html.#{template_engine}")
        end

        def action_path
          application_path.join('controllers', @controller_pathname, "#{@action_name.downcase}.rb")
        end

        def action_spec_path
          spec_root.join('controllers', @controller_pathname, "#{ @action_name.downcase}_spec.rb")
        end

        def spec_root
          Pathname.new('spec').join(app_base_dir)
        end

        def relative_action_path
          path = Pathname.new('.').join('..', '..', '..')
          path = path.join('..') if environment.container?
          path.join(application_path, 'controllers', @controller_pathname, @action_name.downcase)
        end

        def relative_view_path
          path = Pathname.new('.').join('..', '..', '..')
          path = path.join('..') if environment.container?
          path.join(application_path, 'views', @controller_pathname, @action_name.downcase)
        end

        def app_base_dir
          if environment.container?
            application_name_as_snake_case
          else
            ''
          end
        end

        def application_name_as_snake_case
          @application_name.gsub(/(.)([A-Z])/,'\1_\2').downcase
        end
      end
    end
  end
end
