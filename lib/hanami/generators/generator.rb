require 'thor'
require 'forwardable'

module Hanami
  # @api private
  module Generators
    # @api private
    class Generator

      extend Forwardable

      # @api private
      def_delegators :@processor, :run, :behavior=, :inject_into_file, :append_to_file, :prepend_to_file, :gsub_file

      # @api private
      class Processor < Thor
        include Thor::Actions
      end

      # @api private
      def initialize(template_source_path, target_path)
        @template_source_path = template_source_path
        @target_path = target_path
        @template_mappings = []
        @processor = Processor.new
        @processor.class.source_root(@template_source_path)
      end

      # @api private
      def add_mapping(source, target)
        @template_mappings << [source, target]
      end

      # @api private
      def process_templates(options = {})
        @template_mappings.each do |src, dst|
          @processor.template(@template_source_path.join(src), @target_path.join(dst), options)
        end
      end

      # Modelled after Thor's `inject_into_class`
      # @api private
      def prepend_after_leading_comments(path, *args, &block)
        config = args.last.is_a?(Hash) ? args.pop : {}
        # Either prepend after the last comment line,
        # or the first line in the file, if there are no comments
        config[:after] = /\A(?:^#.*$\s)*/
        @processor.insert_into_file(path, *(args << config), &block)
      end
    end
  end
end
