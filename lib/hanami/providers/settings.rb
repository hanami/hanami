# frozen_string_literal: true

require "dry/system/provider/source"
require_relative "../constants"
require_relative "../errors"

module Hanami
  module Providers
    # The settings provider loads and registers the "settings" component in app and slice
    # containers.
    #
    # Before registering this provider with a container, you must first subclass at for a
    # given slice using {.for_slice}.
    #
    # @see Slice::ClassMethods.prepare_container_providers
    #
    # @api private
    # @since 2.0.0
    class Settings < Dry::System::Provider::Source
      # Returns true if settings are defined for the slice.
      #
      # Settings are considered defined if a `Settings` class is already defined in the
      # slice namespace, or a `config/settings.rb` exists under the slice root.
      def self.settings_defined?(slice)
        slice.namespace.const_defined?(SETTINGS_CLASS_NAME) ||
          slice.root.join("#{SETTINGS_PATH}#{RB_EXT}").file?
      end

      # Creates a new subclass of the provider for the given slice.
      #
      # You must do this before registering the provider with a container. The provider
      # uses the slice to locate the settings definition based on the slice's config.
      def self.for_slice(slice)
        Class.new(self) do |klass|
          klass.instance_variable_set(:@slice, slice)
        end
      end

      def self.slice
        unless @slice
          raise SliceLoadError, "a slice must be given to #{self} via `.for_slice(slice)`"
        end

        @slice
      end

      def prepare
        require_slice_settings unless slice_settings_class?
      end

      def start
        settings = slice_settings_class.new(slice.config.settings_store)

        register :settings, settings
      end

      private

      def slice
        self.class.slice
      end

      def slice_settings_class?
        slice.namespace.const_defined?(SETTINGS_CLASS_NAME)
      end

      def slice_settings_class
        slice.namespace.const_get(SETTINGS_CLASS_NAME)
      end

      def require_slice_settings
        require "hanami/settings"

        slice_settings_require_path = File.join(slice.root, SETTINGS_PATH)

        begin
          require slice_settings_require_path
        rescue LoadError => e
          raise e unless e.path == slice_settings_require_path
        end
      end
    end
  end
end
