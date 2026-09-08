# frozen_string_literal: true

require "date"
require "dry/core/constants"
require "erb"
require "yaml"

require_relative "../errors"

module Hanami
  class Settings
    # A settings store that loads settings from a YAML file.
    #
    # The file is evaluated as ERB, then parsed as YAML, with its top-level keys becoming the
    # setting names. It is read lazily, on the first fetch, and its contents are then memoized. A
    # file that does not exist, or that is empty, results in an empty store.
    #
    # @example
    #   # config/app.rb
    #   config.settings_store = Hanami::Settings::YamlFileStore.new(config.root.join("my_settings.yml"))
    #
    # @example Resolving the path lazily
    #   # Give a block to resolve the path when the settings are first fetched, rather than when the
    #   # store is created.
    #   config.settings_store = Hanami::Settings::YamlFileStore.new { config.root.join("my_settings.yml") }
    #
    # @api public
    # @since 3.1.0
    class YamlFileStore
      # The classes permitted when parsing the YAML file.
      #
      # @api private
      PERMITTED_CLASSES = [Date, DateTime, Symbol, Time].freeze
      private_constant :PERMITTED_CLASSES

      # @api private
      EMPTY_STORE = Dry::Core::Constants::EMPTY_HASH
      private_constant :EMPTY_STORE

      # Returns a new instance of the store.
      #
      # Give either a path or a block returning a path. The block is called on the first fetch,
      # which allows the path to depend on config (such as the root) that is not yet known when the
      # store is created.
      #
      # @param path [Pathname, String, nil] the path to load the settings from
      #
      # @yieldreturn [Pathname, String] the path to load the settings from
      #
      # @api public
      # @since 3.1.0
      def initialize(path = nil, &block)
        if path.nil? == block.nil?
          raise ArgumentError, "give either a path or a block returning a path"
        end

        @path = path
        @path_resolver = block
      end

      # Returns the path to the YAML file, resolving it from the block given at initialize-time, if
      # any.
      #
      # @return [Pathname, String]
      #
      # @api public
      # @since 3.1.0
      def path
        @path ||= @path_resolver.call
      end

      # @api private
      def fetch(name, *args, &block)
        store.fetch(name.to_sym, *args, &block)
      end

      private

      def store
        @store ||= load_store
      end

      def load_store
        return EMPTY_STORE unless File.exist?(path)

        contents = YAML.load(
          ERB.new(File.read(path)).result,
          aliases: true,
          permitted_classes: PERMITTED_CLASSES,
          symbolize_names: true
        )

        # An empty file (or one containing only comments) parses as `nil`.
        return EMPTY_STORE if contents.nil?

        unless contents.is_a?(Hash)
          raise Hanami::Error, "Expected #{path} to contain a YAML mapping, but it contained a #{contents.class}."
        end

        contents.freeze
      end
    end
  end
end
