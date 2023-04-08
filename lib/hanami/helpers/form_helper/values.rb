# frozen_string_literal: true

require "hanami/utils/hash"

module Hanami
  module Helpers
    module FormHelper
      # Values from params and form helpers.
      #
      # It's responsible to populate input values with data coming from params
      # and inline values specified via form helpers like `text_field`.
      #
      # @since 2.0.0
      # @api private
      class Values
        # @since 2.0.0
        # @api private
        GET_SEPARATOR = "."

        # @api private
        # @since 2.0.0
        attr_reader :csrf_token

        # @since 2.0.0
        # @api private
        # def initialize(values = {}, csrf_token = nil)
        #   @values = Utils::Hash.symbolize(values || {})
        #   @params = values.fetch(:params).to_h
        #   @csrf_token = csrf_token
        # end

        def initialize(values: {}, params: {}, csrf_token: nil)
          @values = values.to_h
          @params = params.to_h
          @csrf_token = csrf_token
        end

        # Returns the value (if present) for the given key.
        # Nested values are expressed with an array if symbols.
        #
        # @since 2.0.0
        # @api private
        def get(*keys)
          _get_from_params(*keys) || _get_from_values(*keys)
        end

        private

        # @since 2.0.0
        # @api private
        def _get_from_params(*keys)
          keys.map! { |key| /\A\d+\z/.match?(key.to_s) ? key.to_s.to_i : key }
          @params.dig(*keys)
        end

        # @since 2.0.0
        # @api private
        def _get_from_values(*keys)
          head, *tail = *keys
          result      = @values[head]

          tail.each do |k|
            break if result.nil?

            result = _dig(result, k)
          end

          result
        end

        # @since 2.0.0
        # @api private
        def _dig(base, key)
          case base
          when ::Hash                       then base[key]
          when Array                        then base[key.to_s.to_i]
          when ->(r) { r.respond_to?(key) } then base.public_send(key)
          end
        end
      end
    end
  end
end
