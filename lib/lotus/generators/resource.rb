require 'lotus/generators/abstract'
require 'lotus/utils/string'

module Lotus
  module Generators
    # @since 0.3.0
    # @api private
    class Resource < Abstract
      # @since 0.3.0
      # @api private
      ACTIONS = %W(index new edit show create update destroy)

      # @since 0.3.0
      # @api private
      SUFFIX           = '.rb'.freeze

      # @since 0.3.0
      # @api private
      def initialize(command)
        super

        @model = name.chop
        @model_name = Utils::String.new(@model).classify

        cli.class.source_root(source)
      end

      # @since 0.3.0
      # @api private
      def start
        assert_existing_app!

        opts = {
          app:           app,
          model_name: @model_name,
          entity_path: _entity_path_without_suffix,
          repository_path: _repository_path_without_suffix
        }

        templates = {
          'entity.rb.tt' => _entity_path,
          'repository.rb.tt'   => _repository_path
        }

        generate_route
        generate_action

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
          "resources :#{name}\n"
        end
      end

      # @since 0.3.0
      # @api private
      def generate_action
        ACTIONS.each do |action|
          Lotus::Commands::Generate.new("action", app_name, "#{name}##{action}", env, cli, action).start
        end
      end

      # @since 0.3.0
      # @api private
      def _routes_path
        app_root.join("config", "routes#{ SUFFIX }")
      end

      # @since 0.3.0
      # @api private
      def _entity_path
        _entity_path_without_suffix.to_s + SUFFIX
      end

      # @since 0.3.0
      # @api private
      def _repository_path
        _repository_path_without_suffix.to_s + SUFFIX
      end

      # @since 0.3.0
      # @api private
      def _entity_path_without_suffix
        model_root.join("entities", @model)
      end

      # @since 0.3.0
      # @api private
      def _repository_path_without_suffix
        model_root.join("repositories", "#{@model}_repository")
      end
    end
  end
end
