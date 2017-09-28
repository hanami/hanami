require 'hanami/commands/generate/abstract'
require 'hanami/commands/generate/migration'

module Hanami
  # @api private
  module Commands
    # @api private
    class Generate
      # @api private
      class Model < Abstract

        # @api private
        attr_reader :input
        # @api private
        attr_reader :model_name
        # @api private
        attr_reader :table_name

        # @api private
        def initialize(options, model_name)
          super(options)
          @input      = Utils::String.new(model_name).underscore
          @model_name = Utils::String.new(@input).classify
          @table_name = if override_table_name?
                          options[:table_name]
                        else
                          Utils::String.new(@input).pluralize
                        end

          unless skip_migration?
            Components.resolve('model.configuration')

            # FIXME: Hanami 2.0
            # Because Hanami::Model::Configuration#migrations uses Pathname#realpath,
            # it's impossible to reference the migrations path if the directory doesn't exist.
            configuration = Components['model.configuration']
            path = Hanami.root.join(configuration.instance_variable_get(:@migrations))
            path.mkpath
          end

          assert_model_name!
        end

        # @api private
        def map_templates
          add_mapping('entity.rb.tt', entity_path)
          add_mapping('repository.rb.tt', repository_path)
          unless skip_migration?
            add_mapping('migration.rb.tt', migration_path)
          end
          add_mapping("entity_spec.#{ test_framework.framework }.tt", entity_spec_path,)
          add_mapping("repository_spec.#{ test_framework.framework }.tt", repository_spec_path)
        end

        # @api private
        def template_options
          {
            model_name: model_name,
            table_name: table_name,
            override_table_name: override_table_name?
          }
        end

        private

        # @since 0.6.0
        # @api private
        def assert_model_name!
          model_name_not_blank
          model_name_valid
        end

        # Validates that a model name was provided
        #
        # @since 0.6.0
        # @api private
        def model_name_not_blank
          if argument_blank?(model_name)
            raise ArgumentError.new('Model name is missing')
          end
        end

        # Validates that the provided model name doesn't start with numbers
        #
        # @since 0.6.0
        # @api private
        def model_name_valid
          unless model_name.match(/^[a-z]/i)
            raise ArgumentError.new("Invalid model name. The model name shouldn't begin with a number.")
          end
        end

        # @api private
        def skip_migration?
          options.fetch(:skip_migration, false)
        end

        # @api private
        def override_table_name?
          !options.fetch(:table_name, '').empty?
        end

        # @api private
        def model_root
          Pathname.new('lib').join(project_name)
        end

        # @since 0.5.0
        # @api private
        def entity_path
          model_root.join('entities', "#{ model_name_underscored }.rb").to_s
        end

        # @since 0.5.0
        # @api private
        def repository_path
          model_root.join('repositories', "#{ model_name_underscored }_repository.rb").to_s
        end

        # @since 0.9.1
        # @api private
        def migration_path
          timestamp = Time.now.utc.strftime(Migration::TIMESTAMP_FORMAT)
          filename = Migration::FILENAME_PATTERN % { timestamp: timestamp, name: "create_#{table_name}"}
          Hanami::Model.configuration.migrations.join(filename)
        end

        # @since 0.5.0
        # @api private
        def entity_spec_path
          target_path.join('spec', project_name, 'entities', "#{ model_name_underscored }_spec.rb")
        end

        # @since 0.5.0
        # @api private
        def repository_spec_path
          target_path.join('spec', project_name, 'repositories',
            "#{ model_name_underscored }_repository_spec.rb")
        end

        # @since 0.5.0
        # @api private
        def model_name_underscored
          input
        end
      end
    end
  end
end
