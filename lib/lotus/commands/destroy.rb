module Lotus
  module Commands
    class Destroy

      ACTION_SEPARATOR = /\/|\#/

      attr_reader :name, :app_name

      def initialize(type, app_name, name, env, cli)
        @cli      = cli
        @options  = env.to_options.merge(cli.options)

        @app_name = app_name

        @name     = name
        @type     = type
      end

      def start
        target_file_paths.each do |target_file_path|
          ::Dir.glob("#{target_file_path}.*").each { |file| ::File.delete(file) }
        end
      end

      def app_root
        @app_root ||= Pathname.new([@options[:path], app_name].join(::File::SEPARATOR))
      end

      def spec_root
        @spec_root ||= Pathname.new('spec')
      end

      private

        def controller_name
          name.split(ACTION_SEPARATOR).first
        end

        def action_name
          name.split(ACTION_SEPARATOR).last
        end

        def _action_path
          app_root.join("controllers", controller_name, action_name)
        end

        def _template_path
          app_root.join("templates", controller_name, action_name)
        end

        def _view_path
          app_root.join("views", controller_name, action_name)
        end

        def _action_spec_path
          spec_root.join(app_name, "controllers", controller_name, "#{action_name}_spec")
        end

        def _template_spec_path
          spec_root.join(app_name, "templates", controller_name, "#{action_name}_spec")
        end

        def _view_spec_path
          spec_root.join(app_name, "views", controller_name, "#{action_name}_spec")
        end

        def target_file_paths
          [_action_path, _template_path, _view_path,
            _action_spec_path, _template_spec_path, _view_spec_path]
        end
    end
  end
end
