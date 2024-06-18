# frozen_string_literal: true

module Hanami
  module Providers
    class DB < Dry::System::Provider::Source
      # @api public
      # @since 2.2.0
      class Config < Dry::Configurable::Config
      end
    end
  end
end
