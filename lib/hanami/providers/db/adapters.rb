# frozen_string_literal: true

module Hanami
  module Providers
    class DB < Dry::System::Provider::Source
      # @api public
      # @since 2.2.0
      class Adapters
        extend Forwardable

        def_delegators :adapters, :[], :[]=, :each, :to_h

        # @api private
        # @since 2.2.0
        attr_reader :adapters

        # @api private
        # @since 2.2.0
        def initialize
          @adapters = Hash.new do |hsh, key|
            hsh[key] = Adapter.new
          end
        end

        # @api private
        # @since 2.2.0
        def initialize_copy(source)
          @adapters = source.adapters.dup
          @adapters.each do |key, val|
            @adapters[key] = val.dup
          end
        end
      end
    end
  end
end
