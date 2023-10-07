# frozen_string_literal: true

require_relative "constants"

module Hanami
  # @api private
  class SliceRegistrar
    VALID_SLICE_NAME_RE = /^[a-z][a-z0-9_]+$/
    SLICE_DELIMITER = CONTAINER_KEY_DELIMITER

    attr_reader :parent, :slices
    private :parent, :slices

    def initialize(parent)
      @parent = parent
      @slices = {}
    end

    def register(name, slice_class = nil, &block)
      unless name.to_s =~ VALID_SLICE_NAME_RE
        raise ArgumentError, "slice name #{name.inspect} must be lowercase alphanumeric text and underscores only"
      end

      return unless filter_slice_names([name]).any?

      if slices.key?(name.to_sym)
        raise SliceLoadError, "Slice '#{name}' is already registered"
      end

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
      slice_configs = root.join(CONFIG_DIR, SLICES_DIR).glob("*#{RB_EXT}")
        .map { _1.basename(RB_EXT) }

      slice_dirs = root.join(SLICES_DIR).glob("*")
        .select(&:directory?)
        .map { _1.basename }

      (slice_dirs + slice_configs).uniq.sort
        .then { filter_slice_names(_1) }
        .each(&method(:load_slice))

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

    # Runs when a slice file has been found inside the app at `config/slices/[slice_name].rb`,
    # or when a slice directory exists at `slices/[slice_name]`.
    #
    # If a slice definition file is found by `find_slice_require_path`, then `load_slice` will
    # require the file before registering the slice class.
    #
    # If a slice class is not found, registering the slice will generate the slice class.
    def load_slice(slice_name)
      slice_require_path = find_slice_require_path(slice_name)
      require slice_require_path if slice_require_path

      slice_class =
        begin
          inflector.constantize("#{slice_module_name(slice_name)}#{MODULE_DELIMITER}Slice")
        rescue NameError => e
          raise e unless e.name.to_s == inflector.camelize(slice_name) || e.name.to_s == :Slice
        end

      register(slice_name, slice_class)
    end

    # Finds the path to the slice's definition file, if it exists, in the following order:
    #
    # 1. `config/slices/[slice_name].rb`
    # 2. `slices/[parent_slice_name]/config/[slice_name].rb` (unless parent is the app)
    # 3. `slices/[slice_name]/config/slice.rb`
    #
    # If the slice is nested under another slice then it will look in the following order:
    #
    # 1. `config/slices/[parent_slice_name]/[slice_name].rb`
    # 2. `slices/[parent_slice_name]/config/[slice_name].rb`
    # 3. `slices/[parent_slice_name]/[slice_name]/config/slice.rb`
    def find_slice_require_path(slice_name)
      app_slice_file_path = [slice_name]
      app_slice_file_path.prepend(parent.slice_name) unless parent.eql?(parent.app)
      ancestors = [
        parent.app.root.join(CONFIG_DIR, SLICES_DIR, app_slice_file_path.join(File::SEPARATOR)),
        parent.root.join(CONFIG_DIR, SLICES_DIR, slice_name),
        root.join(SLICES_DIR, slice_name, CONFIG_DIR, "slice")
      ]

      ancestors
        .uniq
        .find { _1.sub_ext(RB_EXT).file? }
        &.to_s
    end

    def build_slice(slice_name, &block)
      slice_module =
        begin
          inflector.constantize(slice_module_name(slice_name))
        rescue NameError
          parent_slice_namespace.const_set(inflector.camelize(slice_name), Module.new)
        end

      slice_module.const_set(:Slice, Class.new(Hanami::Slice, &block))
    end

    def slice_module_name(slice_name)
      inflector.camelize("#{parent_slice_namespace.name}#{PATH_DELIMITER}#{slice_name}")
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
