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
        # Register a lazy instance of RoutesHelper to ensure we don't load prematurely
        # load the router during the process of booting. This ensures the router's
        # resolver can run strict action key checks once when it runs on a fully booted
        # slice.
        register :routes do
          Hanami::Slice::RoutesHelper.new(self.class.slice.router)
        end
      end
    end
  end
end
