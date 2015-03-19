require 'lotus/generators/abstract'
require 'lotus/utils/string'

module Lotus
  module Generators
    class Action < Abstract
      ACTION_SEPARATOR = /\/|\#/
      SUFFIX           = '.rb'.freeze
      TEMPLATE_SUFFIX  = '.html.'.freeze
      DEFAULT_TEMPLATE = 'erb'.freeze

      def initialize(command)
        super

        @controller, @action = name.split(ACTION_SEPARATOR)
        @controller_name     = Utils::String.new(@controller).classify
        @action_name         = Utils::String.new(@action).classify

        cli.class.source_root(source)
      end

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

        templates = {
          'action.rb.tt' => _action_path,
          'view.rb.tt'   => _view_path,
          'template.tt'  => _template_path
        }

        case options[:test]
        when 'rspec'
          templates.merge!({
            'action_spec.rspec.tt' => _action_spec_path,
            'view_spec.rspec.tt'   => _view_spec_path,
          })
        else
          templates.merge!({
            'action_spec.minitest.tt' => _action_spec_path,
            'view_spec.minitest.tt'   => _view_spec_path,
          })
        end

        generate_route

        templates.each do |src, dst|
          cli.template(source.join(src), target.join(dst), opts)
        end
      end

      private
      def assert_existing_app!
        unless target.join(app_root).exist?
          raise Lotus::Commands::Generate::Error.new("Unknown app: `#{ app_name }'")
        end
      end

      def generate_route
        path = target.join(_routes_path)
        path.dirname.mkpath

        FileUtils.touch(path)

        # Insert at the top of the file
        cli.insert_into_file _routes_path, before: /\A(.*)/ do
          "get '/#{ @controller }', to: '#{ name }'\n"
        end
      end

      def _routes_path
        app_root.join("config", "routes#{ SUFFIX }")
      end

      def _action_path
        _action_path_without_suffix.to_s + SUFFIX
      end

      def _view_path
        _view_path_without_suffix.to_s + SUFFIX
      end

      def _action_path_without_suffix
        app_root.join("controllers", @controller, "#{ @action }")
      end

      def _view_path_without_suffix
        app_root.join("views", @controller, "#{ @action }")
      end

      def _template_path
        app_root.join("templates", @controller, "#{ @action }#{ TEMPLATE_SUFFIX }#{ options.fetch(:template) { DEFAULT_TEMPLATE } }")
      end

      def _action_spec_path
        spec_root.join(app_name, 'controllers', @controller, "#{ @action }_spec#{ SUFFIX }")
      end

      def _view_spec_path
        spec_root.join(app_name, 'views', @controller, "#{ @action }_spec#{ SUFFIX }")
      end
    end
  end
end
