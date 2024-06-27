# frozen_string_literal: true

module Hanami
  module Provider
    class Source < Dry::System::Provider::Source
      # This would also work, with less overall change (no need for additional `#initialize` args):
      #
      #   alias_method :slice, :target_container
      #
      # However, I'm showing the below to demonstrate an even more flexible approach.

      attr_reader :slice

      def initialize(slice:, **options, &block)
        @slice = slice
        super(**options, &block)
      end
    end
  end
end
