# frozen_string_literal: true

module Hanami
  class Application
    class Action < Hanami::Action
      class ViewNameInferrer
        ALTERNATIVE_NAMES = {
          "create" => "new",
          "update" => "edit"
        }.freeze

        class << self
          def call(action_name:, provider:)
            application = provider.respond_to?(:application) ? provider.application : Hanami.application

            action_identifier_base = application.config.actions.name_inference_base
            view_identifier_base = application.config.actions.view_name_inference_base

            identifier = action_identifier_name(action_name, provider, action_identifier_base)

            view_name = [view_identifier_base, identifier].compact.join(".")

            [view_name, alternative_view_name(view_name)].compact
          end

          private

          def action_identifier_name(action_name, provider, name_base)
            provider
              .inflector
              .underscore(action_name)
              .sub(/^#{provider.namespace_path}\//, "")
              .sub(/^#{name_base}\//, "")
              .gsub("/", ".")
          end

          def alternative_view_name(view_name)
            parts = view_name.split(".")

            alternative_name = ALTERNATIVE_NAMES[parts.last]

            [parts[0..-2], alternative_name].join(".") if alternative_name
          end
        end
      end
    end
  end
end
