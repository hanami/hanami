require 'hanami/generators/generator'

module Hanami
  module Generators
    module Generatable

      def start
        map_templates
        process_templates
      end

      def destroy
        generator.behavior = :revoke
        self
      end

      def generator
        @generator ||= Hanami::Generators::Generator.new(template_source_path, target_path)
      end

      def map_templates
        raise NotImplementedError, "must implement the map_templates method"
      end

      def add_mapping(source, target)
        generator.add_mapping(source, target)
      end

      def process_templates
        generator.process_templates(template_options)
        post_process_templates
      end

      def post_process_templates
        nil
      end

      def template_options
        {}
      end

      def template_source_path
        raise NotImplementedError, "must implement the template_source_path method"
      end

      def target_path
        raise NotImplementedError, "must implement the target_path method"
      end

      def argument_blank?(value)
        Hanami::Utils::Blank.blank?(value)
      end

    end
  end
end
