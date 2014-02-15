require 'lotus/utils/class'
require 'lotus/view/internal_server_error_view'
require 'lotus/view/not_found_view'

module Lotus
  module View
    class ViewLoader
      SUCCESSFUL_STATES   = (200..201).freeze
      CLASS_PREFIX        = 'Lotus::View::'.freeze
      CLASS_SUFFIX        = 'View'.freeze
      NAMESPACE_SEPARATOR = '::'.freeze
      SUFFIX_REPLACEMENT  = ''.freeze

      def self.load!(response, config)
        Utils::Class.load! class_name_for(response, config)
      end

      private
      def self.class_name_for(response, config)
        case response[0]
        when SUCCESSFUL_STATES
          class_name_from_action(response, config)
        else
          class_name_from_status(response)
        end
      end

      def self.class_name_from_action(response, config)
        action = response[3]
        namespace, action_name = _extract_namespace_and_action_name(action, config.dup)
        "#{ namespace }::(#{ config.view_namespace }#{ action_name }|#{ action_name }#{ config.view_suffix })"
      end

      def self.class_name_from_status(response)
        _, name = Http::Status.for_code(response[0])
        CLASS_PREFIX + name.gsub(' ', '') + CLASS_SUFFIX
      end

      def self._extract_namespace_and_action_name(action, config)
        namespace, alternate_action_name, action_name = action.class.name.split(NAMESPACE_SEPARATOR)
        [ namespace.gsub(config.controller_suffix, SUFFIX_REPLACEMENT), action_name || alternate_action_name ]
      end
    end
  end
end
