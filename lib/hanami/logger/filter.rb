# frozen_string_literal: true

require "logger"

module Hanami
  class Logger < ::Logger
    # Filtering logic
    #
    # @since 1.1.0
    # @api private
    class Filter
      # @since 1.3.7
      # @api private
      FILTERED_VALUE = "[FILTERED]"

      def initialize(filters = [], mask: FILTERED_VALUE)
        @filters = filters
        @mask = mask
      end

      # @since 1.1.0
      # @api private
      def call(params)
        _filter(_copy_params(params))
      end

      private

      # @since 1.1.0
      # @api private
      attr_reader :filters

      # @since 1.3.7
      # @api private
      attr_reader :mask

      # This is a simple deep merge to merge the original input
      # with the filtered hash which contains '[FILTERED]' string.
      #
      # It only deep-merges if the conflict values are both hashes.
      #
      # @since 1.3.7
      # @api private
      def _deep_merge(original_hash, filtered_hash)
        original_hash.merge(filtered_hash) do |_key, original_item, filtered_item|
          if original_item.is_a?(Hash) && filtered_item.is_a?(Hash)
            _deep_merge(original_item, filtered_item)
          elsif filtered_item == FILTERED_VALUE
            filtered_item
          else
            original_item
          end
        end
      end

      # @since 1.1.0
      # @api private
      def _filtered_keys(hash)
        _key_paths(hash).select { |key| filters.any? { |filter| key =~ %r{(\.|\A)#{filter}(\.|\z)} } }
      end

      # @since 1.1.0
      # @api private
      def _key_paths(hash, base = nil)
        hash.inject([]) do |results, (k, v)|
          results + (_key_paths?(v) ? _key_paths(v, _build_path(base, k)) : [_build_path(base, k)])
        end
      end

      # @since 1.1.0
      # @api private
      def _build_path(base, key)
        [base, key.to_s].compact.join(".")
      end

      # @since 1.1.0
      # @api private
      def _actual_keys(hash, keys)
        search_in = hash

        keys.inject([]) do |res, key|
          correct_key = search_in.key?(key.to_sym) ? key.to_sym : key
          search_in = search_in[correct_key]
          res + [correct_key]
        end
      end

      # Check if the given value can be iterated (`Enumerable`) and that isn't a `File`.
      # This is useful to detect closed `Tempfiles`.
      #
      # @since 1.3.5
      # @api private
      #
      # @see https://github.com/hanami/cyg_utils/pull/342
      def _key_paths?(value)
        value.is_a?(Enumerable) && !value.is_a?(File)
      end

      # @since 1.3.7
      # @api private
      def _deep_dup(hash)
        hash.map do |key, value|
          [
            key,
            if value.is_a?(Hash)
              _deep_dup(value)
            else
              _key_paths?(value) ? value.dup : value
            end
          ]
        end.to_h
      end

      # @since 1.3.7
      # @api private
      def _copy_params(params)
        case params
        when Hash
          _deep_dup(params)
        when Array
          params.map { |hash| _deep_dup(hash) }
        end
      end

      # @since 1.3.7
      # @api private
      def _filter_hash(hash)
        _filtered_keys(hash).each do |key|
          *keys, last = _actual_keys(hash, key.split("."))
          keys.inject(hash, :fetch)[last] = mask
        end
        hash
      end

      # @since 1.3.7
      # @api private
      def _filter(params)
        case params
        when Hash
          _filter_hash(params)
        when Array
          params.map { |hash| _filter_hash(hash) }
        end
      end
    end
  end
end
