require 'hanami/generators/generator'

module Hanami
  # @api private
  module Generators
    # @api private
    module Generatable

      # @api private
      def start
        map_templates
        process_templates
      end

      # @api private
      def destroy
        generator.behavior = :revoke
        self
      end

      # @api private
      def generator
        @generator ||= Hanami::Generators::Generator.new(template_source_path, target_path)
      end

      # @api private
      def map_templates
        raise NotImplementedError, "must implement the map_templates method"
      end

      # @api private
      def add_mapping(source, target)
        generator.add_mapping(source, target)
      end

      # @api private
      def process_templates
        generator.process_templates(template_options)
        post_process_templates
      end

      # @api private
      def post_process_templates
        nil
      end

      # @api private
      def template_options
        {}
      end

      # @api private
      def template_source_path
        raise NotImplementedError, "must implement the template_source_path method"
      end

      # @api private
      def target_path
        raise NotImplementedError, "must implement the target_path method"
      end

      # @api private
      def argument_blank?(value)
        Hanami::Utils::Blank.blank?(value)
      end

    end
  end
end
