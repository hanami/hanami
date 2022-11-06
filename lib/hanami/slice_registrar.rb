# frozen_string_literal: true

require_relative "constants"

module Hanami
  # @api private
  class SliceRegistrar
    SLICE_DELIMITER = CONTAINER_KEY_DELIMITER

    attr_reader :parent, :slices
    private :parent, :slices

    def initialize(parent)
      @parent = parent
      @slices = {}
    end

    def register(name, slice_class = nil, &block)
      return unless filter_slice_names([name]).any?

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
      slice_configs = Dir[root.join(CONFIG_DIR, SLICES_DIR, "*#{RB_EXT}")]
        .map { |file| File.basename(file, RB_EXT) }

      slice_dirs = Dir[File.join(root, SLICES_DIR, "*")]
        .select { |path| File.directory?(path) }
        .map { |path| File.basename(path) }

      slice_names = (slice_dirs + slice_configs).uniq.sort
        .then { filter_slice_names(_1) }

      slice_names.each do |slice_name|
        load_slice(slice_name)
      end

      self
    end

    def each(&block)
      slices.each_value(&block)
    end

    def keys
      slices.keys
    end

    def to_a
      slices.values
    end

    def with_nested
      to_a.flat_map { |slice|
        # Return nested slices first so that their more specific namespaces may be picked up first
        # by SliceConfigurable#slice_for
        slice.slices.with_nested + [slice]
      }
    end

    private

    def root
      parent.root
    end

    def inflector
      parent.inflector
    end

    def parent_slice_namespace
      parent.eql?(parent.app) ? Object : parent.namespace
    end

    # Runs when a slice file has been found at `config/slices/[slice_name].rb`, or a slice directory
    # at `slices/[slice_name]`. Attempts to require the slice class, if defined, before registering
    # the slice. If a slice class is not found, registering the slice will generate the slice class.
    def load_slice(slice_name)
      slice_require_path = root.join(CONFIG_DIR, SLICES_DIR, slice_name).to_s
      begin
        require(slice_require_path)
      rescue LoadError => e
        raise e unless e.path == slice_require_path
      end

      slice_module_name = inflector.camelize("#{parent_slice_namespace.name}#{PATH_DELIMITER}#{slice_name}")
      slice_class =
        begin
          inflector.constantize("#{slice_module_name}#{MODULE_DELIMITER}Slice")
        rescue NameError => e
          raise e unless e.name.to_s == inflector.camelize(slice_name) || e.name.to_s == :Slice
        end

      register(slice_name, slice_class)
    end

    def build_slice(slice_name, &block)
      slice_module_name = inflector.camelize("#{parent_slice_namespace.name}#{PATH_DELIMITER}#{slice_name}")
      slice_module =
        begin
          inflector.constantize(slice_module_name)
        rescue NameError
          parent_slice_namespace.const_set(inflector.camelize(slice_name), Module.new)
        end

      slice_module.const_set(:Slice, Class.new(Hanami::Slice, &block))
    end

    def configure_slice(slice_name, slice)
      slice.instance_variable_set(:@parent, parent)

      # Slices require a root, so provide a sensible default based on the slice's parent
      slice.config.root ||= root.join(SLICES_DIR, slice_name.to_s)

      slice.config.slices = child_slice_names(slice_name, parent.config.slices)
    end

    # Returns a filtered array of slice names based on the parent's `config.slices`
    #
    # This works with both singular slice names (e.g. `"admin"`) as well as dot-delimited nested
    # slice names (e.g. `"admin.shop"`).
    #
    # It will consider only the base names of the slices (since in this case, a parent slice must be
    # loaded in order for its children to be loaded).
    #
    # @example
    #   parent.config.slices # => ["admin.shop"]
    #   filter_slice_names(["admin", "main"]) # => ["admin"]
    #
    #   parent.config.slices # => ["admin"]
    #   filter_slice_names(["admin", "main"]) # => ["admin"]
    def filter_slice_names(slice_names)
      slice_names = slice_names.map(&:to_s)

      if parent.config.slices
        slice_names & parent.config.slices.map { base_slice_name(_1) }
      else
        slice_names
      end
    end

    # Returns the base slice name from an (optionally) dot-delimited nested slice name.
    #
    # @example
    #   base_slice_name("admin") # => "admin"
    #   base_slice_name("admin.users") # => "admin"
    def base_slice_name(name)
      name.to_s.split(SLICE_DELIMITER).first
    end

    # Returns an array of slice names specific to the given child slice.
    #
    # @example
    #   child_local_slice_names("admin", ["main", "admin.users"]) # => ["users"]
    def child_slice_names(parent_slice_name, slice_names)
      slice_names
        &.select { |name|
          name.include?(SLICE_DELIMITER) && name.split(SLICE_DELIMITER)[0] == parent_slice_name.to_s
        }
        &.map { |name|
          name.split(SLICE_DELIMITER)[1..].join(SLICE_DELIMITER) # which version of Ruby supports this?
        }
    end
  end
end
