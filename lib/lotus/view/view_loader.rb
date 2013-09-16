require 'lotus/utils/class'

module Lotus
  module View
    class ViewLoader
      NAMESPACE_SEPARATOR = '::'.freeze
      SUFFIX_REPLACEMENT  = ''.freeze

      def initialize(action, config)
        namespace, action_name = _extract_namespace_and_action_name(action, config.dup)
        @class_name = "#{ namespace }::(#{ config.view_namespace }#{ action_name }|#{ action_name }#{ config.view_suffix })"
      end

      def load!
        Utils::Class.load!(@class_name)
      end

      private
      def _extract_namespace_and_action_name(action, config)
        namespace, alternate_action_name, action_name = action.class.name.split(NAMESPACE_SEPARATOR)
        [ namespace.gsub(config.controller_suffix, SUFFIX_REPLACEMENT), action_name || alternate_action_name ]
      end
    end
  end
end
