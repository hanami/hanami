require 'lotus/generators/abstract'
require 'lotus/utils/string'

module Lotus
  module Generators
    # @since 0.3.0
    # @api private
    class Action < Abstract
      # @since 0.3.0
      # @api private
      ACTION_SEPARATOR = /\/|\#/

      # @since 0.3.0
      # @api private
      SUFFIX           = '.rb'.freeze

      # @since 0.3.0
      # @api private
      TEMPLATE_SUFFIX  = '.html.'.freeze

      # @since 0.3.0
      # @api private
      DEFAULT_TEMPLATE = 'erb'.freeze

      # @since 0.3.0
      # @api private
      def initialize(command)
        super

        @controller, @action = name.split(ACTION_SEPARATOR)
        @controller_name     = Utils::String.new(@controller).classify
        @action_name         = Utils::String.new(@action).classify

        cli.class.source_root(source)
      end

      # @since 0.3.0
      # @api private
      def start
        assert_existing_app!

        opts = {
          app:           app,
          controller:    @controller_name,
          action:        @action_name,
          action_path:   _action_path_without_suffix,
          view_path:     _view_path_without_suffix,
          template_path: _template_path,
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

      # @since 0.3.0
      # @api private
      def generate_route
        path = target.join(_routes_path)
        path.dirname.mkpath

        FileUtils.touch(path)

        # Insert at the top of the file
        cli.insert_into_file _routes_path, before: /\A(.*)/ do
          "get '/#{ @controller }', to: '#{ name }'\n"
        end
      end

      # @since 0.3.0
      # @api private
      def _routes_path
        app_root.join("config", "routes#{ SUFFIX }")
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
        spec_root.join(app_name, 'controllers', @controller, "#{ @action }_spec#{ SUFFIX }")
      end

      # @since 0.3.0
      # @api private
      def _view_spec_path
        spec_root.join(app_name, 'views', @controller, "#{ @action }_spec#{ SUFFIX }")
      end
    end
  end
end
