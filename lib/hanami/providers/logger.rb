# frozen_string_literal: true

require "dry/system/provider/source"

module Hanami
  module Providers
    class Logger < Dry::System::Provider::Source
      def start
        register :logger, Hanami.app.config.logger_instance
      end
    end
  end
end
