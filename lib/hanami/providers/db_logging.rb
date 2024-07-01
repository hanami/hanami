# frozen_string_literal: true

module Hanami
  module Providers
    # @api private
    # @since 2.2.0
    class DBLogging < Dry::System::Provider::Source
      # @api private
      # @since 2.2.0
      def prepare
        require "dry/monitor/sql/logger"
        target["notifications"].register_event :sql
      end

      # @api private
      # @since 2.2.0
      def start
        Dry::Monitor::SQL::Logger.new(target["logger"]).subscribe(target["notifications"])
      end
    end
  end
end
