# frozen_string_literal: true

require "hanami/utils/basic_object"

module Hanami
  class Application
    module Settings
      # Application settings definition DSL
      #
      # @since 2.0.0
      # @api private
      class Definition < Hanami::Utils::BasicObject
        attr_reader :settings

        def initialize(&block)
          @settings = []
          instance_eval(&block) if block
        end

        def setting(name, *args)
          @settings << [name, args]
        end
      end
    end
  end
end
