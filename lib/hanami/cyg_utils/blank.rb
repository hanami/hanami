# frozen_string_literal: true

module Hanami
  module CygUtils
    # Checks for blank
    #
    # @since 0.8.0
    # @api private
    class Blank
      # Matcher for blank strings
      #
      # @since 0.8.0
      # @api private
      STRING_MATCHER = /\A[[:space:]]*\z/.freeze

      # Checks if object is blank
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/blank'
      #
      #   Hanami::CygUtils::Blank.blank?(Hanami::CygUtils::String.new('')) # => true
      #   Hanami::CygUtils::Blank.blank?('  ')                          # => true
      #   Hanami::CygUtils::Blank.blank?(nil)                           # => true
      #   Hanami::CygUtils::Blank.blank?(Hanami::CygUtils::Hash.new({}))   # => true
      #   Hanami::CygUtils::Blank.blank?(true)                          # => false
      #   Hanami::CygUtils::Blank.blank?(1)                             # => false
      #
      # @param object the argument
      #
      # @return [TrueClass,FalseClass] info, whether object is blank
      #
      # @since 0.8.0
      # @api private
      def self.blank?(object)
        case object
        when String, ::String
          STRING_MATCHER === object # rubocop:disable Style/CaseEquality
        when Hash, ::Hash, ::Array
          object.empty?
        when TrueClass, Numeric
          false
        when FalseClass, NilClass
          true
        else
          object.respond_to?(:empty?) ? object.empty? : !self
        end
      end

      # Checks if object is filled
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/blank'
      #
      #   Hanami::CygUtils::Blank.filled?(true)                          # => true
      #   Hanami::CygUtils::Blank.filled?(1)                             # => true
      #   Hanami::CygUtils::Blank.filled?(Hanami::CygUtils::String.new('')) # => false
      #   Hanami::CygUtils::Blank.filled?('  ')                          # => false
      #   Hanami::CygUtils::Blank.filled?(nil)                           # => false
      #   Hanami::CygUtils::Blank.filled?(Hanami::CygUtils::Hash.new({}))   # => false
      #
      # @param object the argument
      #
      # @return [TrueClass,FalseClass] whether the object is filled
      #
      # @since 1.0.0
      # @api private
      def self.filled?(object)
        !blank?(object)
      end
    end
  end
end
