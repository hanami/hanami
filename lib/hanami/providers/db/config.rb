# frozen_string_literal: true

require "dry/core"

module Hanami
  module Providers
    class DB < Dry::System::Provider::Source
      # @api public
      # @since 2.2.0
      class Config < Dry::Configurable::Config
        include Dry::Core::Constants

        def adapter(adapter_name = Undefined)
          return self[:adapter] if adapter_name.eql?(Undefined)

          yield adapters[adapter_name] ||= Adapter.new
        end

        def any_adapter
          yield adapters[nil] ||= Adapter.new
        end
      end
    end
  end
end
