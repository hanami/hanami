require 'lotus/commands/generate/abstract'

module Lotus
  module Commands
    class Generate
      class Model < Abstract

        attr_reader :model_name

        def initialize(options, model_name)
          super(options)
          @model_name = Utils::String.new(model_name).classify

          assert_model_name!
        end

        def map_templates
          add_mapping('entity.rb.tt', entity_path)
          add_mapping('repository.rb.tt', repository_path)
          add_mapping("entity_spec.#{ test_framework.framework }.tt", entity_spec_path,)
          add_mapping("repository_spec.#{ test_framework.framework }.tt", repository_spec_path)
        end

        def template_options
          {
            model_name: model_name
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
          if model_name.nil? || model_name.strip.empty?
            raise ArgumentError.new('Model name nil or empty.')
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

        def model_root
          Pathname.new('lib').join(::File.basename(Dir.getwd))
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

        # @since 0.5.0
        # @api private
        def entity_spec_path
          target_path.join('spec', ::File.basename(Dir.getwd), 'entities', "#{ model_name_underscored }_spec.rb")
        end

        # @since 0.5.0
        # @api private
        def repository_spec_path
          target_path.join('spec', ::File.basename(Dir.getwd), 'repositories',
            "#{ model_name_underscored }_repository_spec.rb")
        end

        # @since 0.5.0
        # @api private
        def model_name_underscored
          Utils::String.new(model_name).underscore
        end
      end
    end
  end
end
