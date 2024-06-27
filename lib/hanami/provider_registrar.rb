# frozen_string_literal: true

# @api private
# @since 2.2.0
module Hanami
  class ProviderRegistrar < Dry::System::ProviderRegistrar
    def self.for_slice(slice)
      Class.new(self) do
        define_singleton_method(:new) do |container|
          super(container, slice)
        end
      end
    end

    attr_reader :slice

    def initialize(container, slice)
      super(container)
      @slice = slice
    end

    def target_container
      slice
    end

    def provider_source_options
      {slice: slice}
    end
  end
end
