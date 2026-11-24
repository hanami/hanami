# frozen_string_literal: true

module Hanami
  module Providers
    class I18n < Hanami::Provider::Source
      # The default I18n backend for a slice. It is an `I18n::Backend::Simple` that loads only the
      # translation files given to it.
      #
      # A regular `I18n::Backend::Simple` loads the files in the global `I18n.load_path` when it
      # first initializes, and again after `reload!`. This backend loads its own files instead, so
      # each slice contains only the translations configured for it, and keeps them after `reload!`.
      #
      # @api private
      class SimpleBackend < ::I18n::Backend::Simple
        attr_reader :translation_files

        # @param translation_files [Array<String>] paths of the translation files to load
        def initialize(translation_files)
          super()
          @translation_files = translation_files.dup.freeze
        end

        protected

        def init_translations
          # Guard against an empty list, since `load_translations` with no arguments loads the
          # global `I18n.load_path`.
          load_translations(*translation_files) unless translation_files.empty?
          @initialized = true
        end
      end
    end
  end
end
