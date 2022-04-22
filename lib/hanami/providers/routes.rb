# frozen_string_literal: true

require "dry/system/provider/source"

module Hanami
  module Providers
    class Routes < Dry::System::Provider::Source
      def self.for_slice(slice)
        Class.new(self) do |klass|
          klass.instance_variable_set(:@slice, slice)
        end
      end

      def self.slice
        @slice || Hanami.application
      end

      def prepare
        require "hanami/slice/routes_helper"
      end

      def start
        # TODO: Determine if this proc is still needed
        register :routes, Hanami::Slice::RoutesHelper.new(-> { self.class.slice.router })
      end
    end
  end
end
