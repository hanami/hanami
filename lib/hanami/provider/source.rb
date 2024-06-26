# frozen_string_literal: true

require "dry/system"

module Hanami
  module Provider
    class Source < Dry::System::Provider::Source
      # @api private
      def self.for_slice(slice)
        namespace = slice.slice_name.namespace

        unless defined?(namespace::Provider)
          namespace.const_set :Provider, Module.new
        end

        Class.new(self).tap do |klass|
          klass.defines :slice
          klass.slice slice

          klass.define_singleton_method(:name) {
            "#{namespace}::Provider::Source"
          }

          namespace::Provider.const_set :Source, klass
        end
      end

      # @api public
      # @since 2.2.0
      def slice = self.class.slice
      alias_method :target_container, :slice
      alias_method :target, :slice
    end
  end
end

