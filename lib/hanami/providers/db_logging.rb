# frozen_string_literal: true

module Hanami
  module Providers
    # @api private
    class DBLogging < Hanami::Provider::Source
      def prepare
        slice["notifications"].register_event :sql
      end

      def start
        require "hanami/logger/sql_logger"
        Hanami::Logger::SQLLogger.new(slice["logger"]).subscribe(slice["notifications"])
      end
    end
  end
end
