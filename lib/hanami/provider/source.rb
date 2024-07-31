# frozen_string_literal: true

module Hanami
  module Provider
    class Source < Dry::System::Provider::Source
      attr_reader :slice

      alias_method :target_container, :slice
      alias_method :target, :slice

      def initialize(slice:, **options, &block)
        @slice = slice
        super(**options, &block)
      end
    end
  end
end
