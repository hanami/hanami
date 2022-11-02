# frozen_string_literal: true

module Hanami
  # @api private
  module Providers
    # Provider source to register routes helper component in Hanami slices.
    #
    # @see Hanami::Slice::RoutesHelper
    #
    # @api private
    # @since 2.0.0
    class Routes < Dry::System::Provider::Source
      # @api private
      def self.for_slice(slice)
        Class.new(self) do |klass|
          klass.instance_variable_set(:@slice, slice)
        end
      end

      # @api private
      def self.slice
        @slice || Hanami.app
      end

      # @api private
      def prepare
        require "hanami/slice/routes_helper"
      end

      # @api private
      def start
        # Register a lazy instance of RoutesHelper to ensure we don't load prematurely load the
        # router during the process of booting. This ensures the router's resolver can run strict
        # action key checks once when it runs on a fully booted slice.
        register :routes do
          Hanami::Slice::RoutesHelper.new(self.class.slice.router)
        end
      end
    end
  end
end
