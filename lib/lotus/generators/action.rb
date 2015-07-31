require 'lotus/generators/abstract'
require 'lotus/utils/string'
require 'lotus/routing/route'

module Lotus
  module Generators
    # @since 0.3.0
    # @api private
    class Action < Abstract
      # @since 0.3.0
      # @api private
      ACTION_SEPARATOR = /\/|\#/

      # @since 0.4.1
      # @api private
      ROUTE_ENDPOINT_SEPARATOR = '#'.freeze

      # @since 0.4.1
      # @api private
      QUOTED_NAME = /(\"|\'|\\)/

      # @since 0.3.0
      # @api private
      SUFFIX           = '.rb'.freeze

      # @since 0.3.0
      # @api private
      TEMPLATE_SUFFIX  = '.html.'.freeze

      # @since 0.3.0
      # @api private
      DEFAULT_TEMPLATE = 'erb'.freeze

      # Default HTTP method used when generating an action.
      # @since x.x.x
      # @api private
      DEFAULT_HTTP_METHOD = 'GET'.freeze

      # @since 0.3.0
      # @api private
      def initialize(command)
        super

        @name = Utils::String.new(name).underscore.gsub(QUOTED_NAME, '')
        @controller, @action = @name.split(ACTION_SEPARATOR)
        @controller_name     = Utils::String.new(@controller).classify
        @action_name         = Utils::String.new(@action).classify

        cli.class.source_root(source)
      end

      # @since 0.3.0
      # @api private
      def start
        assert_existing_app!
        assert_action!
        assert_http_method!

        opts = {
          app:                  app,
          controller:           @controller_name,
          action:               @action_name,
          action_path:          _action_path_without_suffix,
          relative_action_path: _relative_action_path,
          relative_view_path:   _relative_view_path,
          view_path:            _view_path_without_suffix,
          template_path:        _template_path,
        }

        test_type = case options[:test]
                    when 'rspec'
                      'rspec'
                    else
                      'minitest'
                    end

        templates = {
          "action_spec.#{test_type}.tt" => _action_spec_path,
        }

        if !options[:skip_view]
          templates.merge!({
            'action.rb.tt' => _action_path,
            'view.rb.tt'   => _view_path,
            'template.tt'  => _template_path,
            "view_spec.#{test_type}.tt" => _view_spec_path,
          })
        else
          templates.merge!({
            'action_without_view.rb.tt' => _action_path,
          })
        end

        generate_route

        templates.each do |src, dst|
          cli.template(source.join(src), target.join(dst), opts)
        end
      end

      private
      # @since 0.3.0
      # @api private
      def assert_existing_app!
        unless target.join(app_root).exist?
          raise Lotus::Commands::Generate::Error.new("Unknown app: `#{ app_name }'")
        end
      end

      # @since 0.3.2
      # @api private
      def assert_action!
        if @action.nil?
          raise Lotus::Commands::Generate::Error.new("Unknown action, please add action's name with this syntax controller_name#action_name")
        end
      end

      # @since x.x.x
      # @api private
      def assert_http_method!
        if !Lotus::Routing::Route::VALID_HTTP_VERBS.include?(_http_method.upcase)
          raise Lotus::Commands::Generate::Error.new("Unknown HTTP method '#{_http_method}', please use one of #{Lotus::Routing::Route::VALID_HTTP_VERBS.join(', ')}.")
        end
      end

      def app
        if env.container?
          super
        else
          env.require_application_environment
          Utils::String.new(Lotus::Application.applications.first).namespace
        end
      end

      # @since 0.3.0
      # @api private
      def generate_route
        path = target.join(_routes_path)
        path.dirname.mkpath

        FileUtils.touch(path)

        # Insert at the top of the file
        cli.insert_into_file _routes_path, before: /\A(.*)/ do
          "#{ _http_method } '#{ _route_url }', to: '#{ _route_endpoint }'\n"
        end
      end

      # @since x.x.x
      # @api private
      def _http_method
        options.fetch(:method, DEFAULT_HTTP_METHOD).downcase
      end

      # @since 0.4.0
      # @api private
      def _route_url
        options.fetch(:url, "/#{ @controller }")
      end

      # @since 0.4.1
      # @api private
      def _route_endpoint
        "#{ @controller }#{ROUTE_ENDPOINT_SEPARATOR}#{ @action }"
      end

      # @since 0.3.0
      # @api private
      def _routes_path
        routes_root = env.container? ? app_root : env.root
        routes_root.join("config", "routes#{ SUFFIX }")
      end

      # @since 0.3.0
      # @api private
      def _action_path
        _action_path_without_suffix.to_s + SUFFIX
      end

      # @since 0.3.0
      # @api private
      def _view_path
        _view_path_without_suffix.to_s + SUFFIX
      end

      # @since 0.3.0
      # @api private
      def _action_path_without_suffix
        app_root.join("controllers", @controller, "#{ @action }")
      end

      # @since 0.3.0
      # @api private
      def _view_path_without_suffix
        app_root.join("views", @controller, "#{ @action }")
      end

      # @since 0.3.0
      # @api private
      def _template_path
        app_root.join("templates", @controller, "#{ @action }#{ TEMPLATE_SUFFIX }#{ options.fetch(:template) { DEFAULT_TEMPLATE } }")
      end

      # @since 0.3.0
      # @api private
      def _action_spec_path
        spec_root.join(app_name.to_s, 'controllers', @controller, "#{ @action }_spec#{ SUFFIX }")
      end

      # @since 0.3.0
      # @api private
      def _view_spec_path
        spec_root.join(app_name.to_s, 'views', @controller, "#{ @action }_spec#{ SUFFIX }")
      end

      # @since 0.4.0
      # @api private
      def _relative_action_path
        result = '../../../'
        result << '../' if env.container?
        result << _action_path_without_suffix.to_s
        result
      end

      # @since 0.4.0
      # @api private
      def _relative_view_path
        result = '../../../'
        result << '../' if env.container?
        result << _view_path_without_suffix.to_s
        result
      end
    end
  end
end
