# frozen_string_literal: true

module Hanami
  module Provider
    class Source < Dry::System::Provider::Source
      attr_reader :slice

      def initialize(slice:, **options, &block)
        @slice = slice
        super(**options, &block)
      end

      def target_container = slice
    end
  end
end
