require 'hanami/commands/generate/abstract'
require 'hanami/routing/route'

module Hanami
  module Commands
    class Generate
      class Action < Abstract

        # @since x.x.x
        # @api private
        ACTION_SEPARATOR_MATCHER = /[\/,#]/

        # @since x.x.x
        # @api private
        CONTROLLER_SEPARATOR = Utils::String::UNDERSCORE_SEPARATOR

        # @since 0.5.0
        # @api private
        ROUTE_ENDPOINT_SEPARATOR = '#'.freeze

        # @since 0.5.0
        # @api private
        QUOTED_NAME = /(\"|\'|\\)/

        # @since x.x.x
        # @api private
        UP_DIRECTORY = '..'.freeze

        # @since x.x.x
        # @api private
        DIRECTORY_TEST_NESTING_LEVELS = 3

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

          *controller_name, @action_name = controller_and_action_name.split(ACTION_SEPARATOR_MATCHER)

          @application_name = Utils::String.new(application_name).classify

          @controller_directory = controller_name
          @controller_name  = controller_name.join(CONTROLLER_SEPARATOR)

          @controller_class_name = Utils::String.new(@controller_name).classify
          @action_class_name = Utils::String.new(@action_name).classify

          @controller_url = @controller_name # FIXME Extract a new class: Utils::Url to handle conversion from paths or this naming

          assert_application_name!
          assert_controller_class_name!
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
            controller:           @controller_class_name,
            action:               @action_class_name,
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

          generator.prepend_after_leading_comments(routes_path, "#{ http_method } '#{ route_url }', to: '#{ route_endpoint }'\n")
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
          RESOURCEFUL_HTTP_METHODS.fetch(@action_class_name, DEFAULT_HTTP_METHOD)
        end

        # @since 0.5.0
        # @api private
        def route_url
          options.fetch(:url, "/#{ @controller_url }#{ resourceful_route_url_suffix }")
        end

        # @since 0.6.0
        # @api private
        def resourceful_route_url_suffix
          RESOURCEFUL_ROUTE_URL_SUFFIXES.fetch(@action_class_name, "")
        end

        # @since 0.5.0
        # @api private
        def route_endpoint
          "#{ @controller_url }#{ ROUTE_ENDPOINT_SEPARATOR }#{ @action_class_name }".downcase
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
        def assert_controller_class_name!
          if argument_blank?(@controller_class_name)
            raise ArgumentError.new("Unknown controller, please add controllers name with this syntax controller_name#action_name")
          end
        end

        # @since 0.5.0
        # @api private
        def assert_action_name!
          if argument_blank?(@action_class_name)
            raise ArgumentError.new("Unknown action, please add actions name with this syntax controller_name#action_name")
          end
        end

        # @since 0.5.0
        # @api private
        def assert_application_name!
          return unless environment.container?
          if argument_blank?(@application_name) || !application_path.exist?
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
            application_path.join(UP_DIRECTORY, 'config', 'routes.rb')
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
          application_path.join('views', *@controller_directory, "#{@action_name}.rb")
        end

        def view_spec_path
          spec_root.join('views', *@controller_directory, "#{@action_name}_spec.rb")
        end

        def template_path
          application_path.join('templates', *@controller_directory, "#{@action_name}.html.#{template_engine.name}")
        end

        def action_path
          application_path.join('controllers', *@controller_directory, "#{@action_name}.rb")
        end

        def action_spec_path
          spec_root.join('controllers', *@controller_directory, "#{@action_name}_spec.rb")
        end

        def spec_root
          Pathname.new('spec').join(app_base_dir)
        end

        def relative_action_path
          relative_base_path.join(application_path, 'controllers', *@controller_directory, @action_name)
        end

        def relative_view_path
          relative_base_path.join(application_path, 'views', *@controller_directory, @action_name)
        end

        def relative_base_path
          nestings = [UP_DIRECTORY] * @controller_name.count(CONTROLLER_SEPARATOR)
          nestings << UP_DIRECTORY if environment.container?

          Pathname.new('.').join(
            *([UP_DIRECTORY] * DIRECTORY_TEST_NESTING_LEVELS), *nestings
          )
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
