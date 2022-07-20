# frozen_string_literal: true

require "dry/system/provider/source"
require_relative "../constants"

module Hanami
  module Providers
    class Settings < Dry::System::Provider::Source
      def self.settings_defined?(slice)
        slice.namespace.const_defined?(SETTINGS_CLASS_NAME) || slice.root.join("#{SETTINGS_PATH}#{RB_EXT}").file?
      end

      def self.for_slice(slice)
        Class.new(self) do |klass|
          klass.instance_variable_set(:@slice, slice)
        end
      end

      def self.slice
        @slice || Hanami.app
      end

      def prepare
        return if slice_settings_class?

        require_slice_settings
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
