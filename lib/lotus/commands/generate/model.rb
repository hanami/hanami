require 'lotus/commands/generate/abstract'
require 'lotus/generators/generator'
require 'lotus/utils/string'

module Lotus
  module Commands
    class Generate
      class Model < Abstract

        attr_reader :model_name

        def initialize(options, model_name)
          super(options)
          @model_name = Utils::String.new(model_name).classify
          @generator = Lotus::Generators::Generator.new(template_source_path, base_path)

          assert_model_name!
        end

        def start
          @generator.add_mapping('entity.rb.tt', entity_path)
          @generator.add_mapping('repository.rb.tt', repository_path)
          @generator.add_mapping("entity_spec.#{ test_framework.framework }.tt", entity_spec_path,)
          @generator.add_mapping("repository_spec.#{ test_framework.framework }.tt", repository_spec_path)

          @generator.process_templates(model_name: model_name)
        end


        private

        def assert_model_name!
          if model_name.nil? || model_name.strip.empty?
            raise ArgumentError.new('Model name nil or empty.')
          end
        end

        def model_root
          Pathname.new('lib').join(::File.basename(Dir.getwd))
        end

        # @since x.x.x
        # @api private
        def entity_path
          model_root.join('entities', "#{ model_name_underscored }.rb").to_s
        end

        # @since x.x.x
        # @api private
        def repository_path
          model_root.join('repositories', "#{ model_name_underscored }_repository.rb").to_s
        end

        # @since x.x.x
        # @api private
        def entity_spec_path
          base_path.join('spec', ::File.basename(Dir.getwd), 'entities', "#{ model_name_underscored }_spec.rb")
        end

        # @since x.x.x
        # @api private
        def repository_spec_path
          base_path.join('spec', ::File.basename(Dir.getwd), 'repositories',
            "#{ model_name_underscored }_repository_spec.rb")
        end

        def model_name_underscored
          Utils::String.new(model_name).underscore
        end
      end
    end
  end
end
