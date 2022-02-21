# frozen_string_literal: true

require_relative "../constants"

module Hanami
  class Application
    # @api private
    class SliceRegistrar
      attr_reader :application
      private :application

      attr_reader :slices
      private :slices

      def initialize(application)
        @application = application
        @slices = {}
      end

      def register(name, slice_class = nil, &block)
        if slices.key?(name.to_sym)
          raise SliceLoadError, "Slice '#{name.to_s}' is already registered"
        end

        # TODO: raise error unless name meets format (i.e. single level depth only)

        slices[name.to_sym] = slice_class || Slice.build_slice(name, &block)
      end

      def [](name)
        slices.fetch(name) do
          raise SliceLoadError, "Slice '#{name}' not found"
        end
      end

      def freeze
        slices.freeze
        super
      end

      def load_slices
        slice_configs = Dir[root.join(CONFIG_DIR, "slices", "*#{RB_EXT}")]
          .map { |file| File.basename(file, RB_EXT) }

        slice_dirs = Dir[File.join(root, SLICES_DIR, "*")]
          .select { |path| File.directory?(path) }
          .map { |path| File.basename(path) }

        (slice_dirs + slice_configs).uniq.sort.each do |slice_name|
          load_slice(slice_name)
        end

        self
      end

      def each(&block)
        slices.each_value(&block)
      end

      def to_a
        slices.values
      end

      private

      # Attempts to load a slice class defined in `config/slices/[slice_name].rb`, then
      # registers the slice with the matching class, if found.
      def load_slice(slice_name)
        slice_const_name = inflector.camelize(slice_name)
        slice_require_path = root.join("config", "slices", slice_name).to_s

        begin
          require(slice_require_path)
        rescue LoadError => e
          raise e unless e.path == slice_require_path
        end

        slice_class =
          begin
            inflector.constantize("#{slice_const_name}::Slice")
          rescue NameError => e
            raise e unless e.name == :Slice
          end

        register(slice_name, slice_class)
      end

      def root
        application.root
      end

      def inflector
        application.inflector
      end
    end
  end
end
