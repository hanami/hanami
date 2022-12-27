# frozen_string_literal: true

module Hanami
  class Slice
    # @api private
    module Routing
      class Endpoint
        SLICE_ACTIONS_KEY_NAMESPACE = "actions"

        attr_reader :slice, :action_key

        def initialize(action_key, slice)
          @action_key     = action_key
          @slice          = slice
          @resolvable_key = "#{SLICE_ACTIONS_KEY_NAMESPACE}.#{@action_key}"

          ensure_action_in_slice
        end

        # Lazily resolve action from the slice to reduce router initialization time, and
        # circumvent endless loops from the action requiring access to router-related
        # concerns (which may not be fully loaded at the time of reading the routes)
        def call(*args)
          action = slice.resolve(resolvable_key) do
            raise Routes::MissingActionError.new(resolvable_key, slice)
          end

          action.call(*args)
        end

        private

        attr_reader :resolvable_key

        def ensure_action_in_slice
          return unless slice.booted?

          raise Routes::MissingActionError.new(resolvable_key, slice) unless slice.key?(resolvable_key)
        end
      end
    end
  end
end
