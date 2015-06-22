require 'lotus/generators/abstract'
require 'lotus/utils/string'

module Lotus
  module Generators
    class Model < Abstract

      # @since 0.3.1
      # @api private
      def initialize(command)
        super

        @model_name = Utils::String.new(name).classify
        cli.class.source_root(source)
      end

      # @since 0.3.1
      # @api private
      def start
        opts = {
          model_name: @model_name
        }

        templates = {
          'entity.rb.tt'     => _entity_path,
          'repository.rb.tt' => _repository_path
        }

        case options[:test]
        when 'rspec'
          templates.merge!({
            'entity_spec.rspec.tt'     => _entity_spec_path,
            'repository_spec.rspec.tt' => _repository_spec_path,
          })
        else
          templates.merge!({
            'entity_spec.minitest.tt'     => _entity_spec_path,
            'repository_spec.minitest.tt' => _repository_spec_path,
          })
        end

        templates.each do |src, dst|
          cli.template(source.join(src), target.join(dst), opts)
        end
      end

      private
      # @since 0.3.1
      # @api private
      def _entity_path
        model_root.join("entities", "#{ name }.rb").to_s
      end

      # @since 0.3.1
      # @api private
      def _repository_path
        model_root.join("repositories", "#{ name }_repository.rb").to_s
      end

      # @since 0.3.1
      # @api private
      def _entity_spec_path
        spec_root.join(::File.basename(Dir.getwd), 'entities', "#{ name }_spec.rb")
      end

      # @since 0.3.1
      # @api private
      def _repository_spec_path
        spec_root.join(::File.basename(Dir.getwd), 'repositories',
          "#{ name }_repository_spec.rb")
      end

      # @since 0.4.0
      # @api private
      def name
        Utils::String.new(app_name || super).underscore
      end
    end
  end
end
