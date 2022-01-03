# frozen_string_literal: true

require "dry/configurable"
require "dry/system/config/component_dirs"

module Hanami
  class Configuration
    # Configuration for slice source dirs
    #
    # @since 2.0.0
    class SourceDirs
      DEFAULT_COMPONENT_DIR_PATHS = %w[lib actions repositories views].freeze
      private_constant :DEFAULT_COMPONENT_DIR_PATHS

      include Dry::Configurable

      setting :component_dirs,
        default: Dry::System::Config::ComponentDirs.new.tap { |dirs|
          DEFAULT_COMPONENT_DIR_PATHS.each do |path|
            dirs.add path
          end
        },
        cloneable: true

      setting :autoload_paths, default: %w[entities]

      private

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _include_all = false)
        config.respond_to?(name) || super
      end
    end
  end
end
