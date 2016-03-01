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

      # Modelled after Thor's `inject_into_class`
      def prepend_after_leading_comments(path, *args, &block)
        config = args.last.is_a?(Hash) ? args.pop : {}
        # Either prepend after the last comment line,
        # or the first line in the file, if there are no comments
        config.merge!(after: /\A(?:^#.*$\s)*/)
        @processor.insert_into_file(path, *(args << config), &block)
      end
    end
  end
end
