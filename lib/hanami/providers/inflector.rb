# frozen_string_literal: true

require "dry/system/provider/source"

module Hanami
  module Providers
    class Inflector < Dry::System::Provider::Source
      def start
        register :inflector, Hanami.app.inflector
      end
    end
  end
end
