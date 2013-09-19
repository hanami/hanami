require 'lotus/utils/class'
require 'lotus/view/internal_server_error_view'

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
        begin
          Utils::Class.load!(@class_name)
        rescue NameError
          _fallback!
          retry
        end
      end

      protected
      def _fallback!
        @class_name = 'Lotus::View::InternalServerErrorView'
      end

      private
      def _extract_namespace_and_action_name(action, config)
        namespace, alternate_action_name, action_name = action.class.name.split(NAMESPACE_SEPARATOR)
        [ namespace.gsub(config.controller_suffix, SUFFIX_REPLACEMENT), action_name || alternate_action_name ]
      end
    end
  end
end
