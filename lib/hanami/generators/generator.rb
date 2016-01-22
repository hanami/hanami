require 'thor'
require 'forwardable'

module Hanami
  module Generators
    class Generator

      extend Forwardable

      def_delegators :@processor, :run, :behavior=, :inject_into_file, :append_to_file, :prepend_to_file

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
    end
  end
end
