# frozen_string_literal: true

require_relative "../constants"

module Hanami
  class Slice
    # Infers a view name for automatically rendering within actions.
    #
    # @api private
    # @since 2.0.0
    class ViewNameInferrer
      ALTERNATIVE_NAMES = {
        "create" => "new",
        "update" => "edit"
      }.freeze

      class << self
        # Returns an array of container keys for views matching the given action.
        #
        # Also provides alternative view keys for common RESTful actions.
        #
        # @example
        #   ViewNameInferrer.call(action_name: "Main::Actions::Posts::Create", slice: Main::Slice)
        #   # => ["views.posts.create", "views.posts.new"]
        #
        # @param action_class_name [String] action class name
        # @param slice [Hanami::Slice, Hanami::Application] Hanami slice containing the action
        #
        # @return [Array<string>] array of paired view container keys
        def call(action_class_name:, slice:)
          action_key_base = slice.config.actions.name_inference_base
          view_key_base = slice.config.actions.view_name_inference_base

          action_name_key = action_name_key(action_class_name, slice, action_key_base)

          view_key = [view_key_base, action_name_key].compact.join(CONTAINER_KEY_DELIMITER)

          [view_key, alternative_view_key(view_key)].compact
        end

        private

        def action_name_key(action_name, slice, key_base)
          slice
            .inflector
            .underscore(action_name)
            .sub(%r{^#{slice.slice_name.path}#{PATH_DELIMITER}}, "")
            .sub(%r{^#{key_base}#{PATH_DELIMITER}}, "")
            .gsub("/", CONTAINER_KEY_DELIMITER)
        end

        def alternative_view_key(view_key)
          parts = view_key.split(CONTAINER_KEY_DELIMITER)

          alternative_name = ALTERNATIVE_NAMES[parts.last]
          return unless alternative_name

          [parts[0..-2], alternative_name].join(CONTAINER_KEY_DELIMITER)
        end
      end
    end
  end
end
