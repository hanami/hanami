# frozen_string_literal: true

module Hanami
  module Extensions
    module Action
      # Infers an action's name (e.g. `posts.show`) from its class name relative to its slice
      # namespace.
      #
      # @api private
      class NameInferrer
        class << self
          # @example
          #   NameInferrer.call(action_class_name: "Main::Actions::Posts::Show", slice: Main::Slice)
          #   # => "posts.show"
          #
          # @param action_class_name [String, nil] the action class name
          # @param slice [Hanami::Slice] the slice the action belongs to
          #
          # @return [String, nil] the inferred name, or nil if `action_class_name` is nil
          def call(action_class_name:, slice:)
            return nil unless action_class_name

            slice
              .inflector
              .underscore(action_class_name)
              .sub(%r{^#{slice.slice_name.path}#{PATH_DELIMITER}}, "")
              .sub(%r{^#{slice.config.actions.name_inference_base}#{PATH_DELIMITER}}, "")
              .gsub("/", CONTAINER_KEY_DELIMITER)
          end
        end
      end
    end
  end
end
