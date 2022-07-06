# frozen_string_literal: true

require "dry/system/provider/source"

module Hanami
  module Providers
    class Settings < Dry::System::Provider::Source
      def self.for_slice(slice)
        Class.new(self) do |klass|
          klass.instance_variable_set(:@slice, slice)
        end
      end

      def self.slice
        @slice || Hanami.application
      end

      def start
        register :settings, self.class.slice.settings
      end
    end
  end
end
