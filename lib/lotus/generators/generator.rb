require 'thor'

module Lotus
  module Generators
    class Generator

      class Processor < Thor
        include Thor::Actions
      end

      def initialize(template_source_path, target_path)
        @template_source_path = template_source_path
        @target_path = target_path
        @template_mappings = []
        @processor = Processor.new
        @processor.class.source_root(@template_source_path)
      end

      def add_mapping(source, target)
        @template_mappings << [source, target]
      end

      def process_templates(options = {})
        @template_mappings.each do |src, dst|
          @processor.template(@template_source_path.join(src), @target_path.join(dst), options)
        end
      end

      def inject_into_file(file, config, &block)
        @processor.inject_into_file(file, config, &block)
      end

      def append_to_file(file, &block)
        @processor.append_to_file(file, &block)
      end

      def run(command, options)
        @processor.run(command, options)
      end

    end
  end
end
