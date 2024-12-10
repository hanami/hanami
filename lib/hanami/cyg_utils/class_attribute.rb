# frozen_string_literal: true

require "set"
require "hanami/cyg_utils/duplicable"

module Hanami
  module CygUtils
    # Inheritable class level variable accessors.
    # @since 0.1.0
    #
    # @see Hanami::CygUtils::ClassAttribute::ClassMethods
    module ClassAttribute
      # @api private
      def self.included(base)
        base.extend ClassMethods
      end

      # @since 0.1.0
      # @api private
      module ClassMethods
        # Defines a class level accessor for the given attribute(s).
        #
        # A value set for a superclass is automatically available by their
        # subclasses, unless a different value is explicitely set within the
        # inheritance chain.
        #
        # @param attributes [Array<Symbol>] a single or multiple attribute name(s)
        #
        # @return [void]
        #
        # @since 0.1.0
        #
        # @example
        #   require 'hanami/cyg_utils/class_attribute'
        #
        #   class Vehicle
        #     include Hanami::CygUtils::ClassAttribute
        #     class_attribute :engines, :wheels
        #
        #     self.engines = 0
        #     self.wheels  = 0
        #   end
        #
        #   class Car < Vehicle
        #     self.engines = 1
        #     self.wheels  = 4
        #   end
        #
        #   class Airplane < Vehicle
        #     self.engines = 4
        #     self.wheels  = 16
        #   end
        #
        #   class SmallAirplane < Airplane
        #     self.engines = 2
        #     self.wheels  = 8
        #   end
        #
        #   Vehicle.engines # => 0
        #   Vehicle.wheels  # => 0
        #
        #   Car.engines # => 1
        #   Car.wheels  # => 4
        #
        #   Airplane.engines # => 4
        #   Airplane.wheels  # => 16
        #
        #   SmallAirplane.engines # => 2
        #   SmallAirplane.wheels  # => 8
        def class_attribute(*attributes)
          singleton_class.class_eval do
            attr_accessor(*attributes)
          end

          class_attributes.merge(attributes)
        end

        protected

        # @see Class#inherited
        # @api private
        def inherited(subclass)
          class_attributes.each do |attr|
            value = send(attr)
            value = Duplicable.dup(value)
            subclass.class_attribute attr
            subclass.send("#{attr}=", value)
          end

          super
        end

        private

        # Class accessor for class attributes.
        # @api private
        def class_attributes
          @class_attributes ||= Set.new
        end
      end
    end
  end
end
