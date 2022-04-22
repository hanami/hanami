# frozen_string_literal: true

require_relative "constants"
require_relative "slice"

module Hanami
  # @api private
  class SliceRegistrar
    attr_reader :parent, :slices
    private :parent, :slices

    def initialize(parent)
      @parent = parent
      @slices = {}
    end

    def register(name, slice_class = nil, &block)
      if slices.key?(name.to_sym)
        raise SliceLoadError, "Slice '#{name}' is already registered"
      end

      # TODO: raise error unless name meets format (i.e. single level depth only)

      slice = slice_class || build_slice(name, &block)

      configure_slice(name, slice)

      slices[name.to_sym] = slice
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
      return self unless root

      slice_configs = Dir[root.join(CONFIG_DIR, SLICES_DIR, "*#{RB_EXT}")]
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

    # Runs when a slice file has been found at `config/slices/[slice_name].rb`, or a slice
    # directory at `slices/[slice_name]`. Attempts to require the slice class, if defined,
    # or generates a new slice class for the given slice name.
    def load_slice(slice_name)
      slice_const_name = inflector.camelize(slice_name)
      slice_require_path = root.join(CONFIG_DIR, SLICES_DIR, slice_name).to_s

      begin
        require(slice_require_path)
      rescue LoadError => e
        raise e unless e.path == slice_require_path
      end

      slice_class =
        begin
          inflector.constantize("#{slice_const_name}::Slice")
        rescue NameError => e
          raise e unless e.name.to_s == slice_const_name || e.name.to_s == :Slice
        end

      register(slice_name, slice_class)
    end

    def build_slice(slice_name, &block)
      slice_module =
        begin
          slice_module_name = inflector.camelize(slice_name.to_s)
          inflector.constantize(slice_module_name)
        rescue NameError
          Object.const_set(inflector.camelize(slice_module_name), Module.new)
        end

      slice_module.const_set(:Slice, Class.new(Hanami::Slice, &block))
    end

    def configure_slice(slice_name, slice)
      slice.instance_variable_set(:@parent, parent)

      # Slices require a root, so provide a sensible default based on the slice's parent
      slice.config.root ||= root.join(SLICES_DIR, slice_name.to_s)
    end

    def root
      parent.root
    end

    def inflector
      parent.inflector
    end
  end
end
