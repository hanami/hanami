# frozen_string_literal: true

require_relative "constants"
require_relative "slice"

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
      return self unless root

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

    private

    def root
      parent.root
    end

    def inflector
      parent.inflector
    end

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

      slice.config.slices.load_slices = child_slice_names(slice_name, parent.config.slices.load_slices)
      slice.config.slices.skip_slices = child_slice_names(slice_name, parent.config.slices.skip_slices)
    end

    # Returns a filtered array of slice names based on the parent's `load_slices` or `skip_slices`
    # config.
    #
    # This works with both singular slice names (e.g. `"admin"`) as well as dot-delimited nested
    # slice names (e.g. `"admin.shop"`).
    #
    # When using the `load_slices` config, it will consider only the base names of the slices (since
    # in this case, a parent slice must be loaded in order for its children to be laoded).
    #
    # @example using `config.slices.load_slices`
    #   parent.config.slices.load_slices # => ["admin.shop"]
    #   filter_slice_names(["admin", "main"]) # => ["admin"]
    #
    #   parent.config.slices.load_slices # => ["admin"]
    #   filter_slice_names(["admin", "main"]) # => ["admin"]
    #
    # When using the `skip_slices` config, it will match exact slice names only (since skipping a
    # nested slice does not necessarily imply that its parent should also be skipped).
    #
    # @example using `config.slices.skip_slices`
    #   parent.config.skip_slices # => ["admin.shop"]
    #   filter_slice_names(["admin", "main"]) # => ["admin", "main"]
    #
    #   parent.config.skp_slices # => ["admin"]
    #   filter_slice_names(["admin", "main"]) # => ["main"]
    #
    # In the case of both `load_slices` and `skip_slices` config, it prefers `load_slices`.
    #
    # @example using both `config.slices.load_slices` and `skip_slices`
    #   parent.config.slices.load_slices # => ["main"]
    #   parent.config.slices.skip_slices # => ["main"]
    #   filter_slice_names(["admin", "main"]) # => ["main"]
    def filter_slice_names(slice_names)
      slice_names = slice_names.map(&:to_s)

      if parent.config.slices.load_slices
        slice_names & parent.config.slices.load_slices.map { base_slice_name(_1) }
      elsif parent.config.slices.skip_slices
        slice_names - parent.config.slices.skip_slices
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
