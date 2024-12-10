# frozen_string_literal: true

require "set"
require "date"
require "time"
require "pathname"
require "bigdecimal"
require "hanami/utils"
require "hanami/cyg_utils/string"

unless defined?(Boolean)
  # Defines top level constant Boolean, so it can be easily used by other libraries
  # in coercions DSLs
  #
  # @since 0.3.0
  class Boolean
  end
end

module Hanami
  module CygUtils
    # Kernel utilities
    # @since 0.1.1
    module Kernel # rubocop:disable Metrics/ModuleLength
      # Matcher for numeric values
      #
      # @since 0.3.3
      # @api private
      #
      # @see Hanami::CygUtils::Kernel.Integer
      NUMERIC_MATCHER = %r{\A([\d\/\.\+iE]+|NaN|Infinity)\z}.freeze

      # @since 0.8.0
      # @api private
      BOOLEAN_FALSE_STRING = "0"

      # @since 0.8.0
      # @api private
      BOOLEAN_TRUE_INTEGER = 1

      # Coerces the argument to be an Array.
      #
      # It's similar to Ruby's Kernel.Array, but it applies further
      # transformations:
      #
      #   * flatten
      #   * compact
      #   * uniq
      #
      # @param arg [Object] the input
      #
      # @return [Array] the result of the coercion
      #
      # @since 0.1.1
      #
      # @see http://www.ruby-doc.org/core/Kernel.html#method-i-Array
      #
      # @see http://www.ruby-doc.org/core/Array.html#method-i-flatten
      # @see http://www.ruby-doc.org/core/Array.html#method-i-compact
      # @see http://www.ruby-doc.org/core/Array.html#method-i-uniq
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.Array(nil)              # => []
      #   Hanami::CygUtils::Kernel.Array(true)             # => [true]
      #   Hanami::CygUtils::Kernel.Array(false)            # => [false]
      #   Hanami::CygUtils::Kernel.Array(1)                # => [1]
      #   Hanami::CygUtils::Kernel.Array([1])              # => [1]
      #   Hanami::CygUtils::Kernel.Array([1, [2]])         # => [1,2]
      #   Hanami::CygUtils::Kernel.Array([1, [2, nil]])    # => [1,2]
      #   Hanami::CygUtils::Kernel.Array([1, [2, nil, 1]]) # => [1,2]
      #
      # @example Array Interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   ResultSet = Struct.new(:records) do
      #     def to_a
      #       records.to_a.sort
      #     end
      #   end
      #
      #   Response = Struct.new(:status, :headers, :body) do
      #     def to_ary
      #       [status, headers, body]
      #     end
      #   end
      #
      #   set = ResultSet.new([2,1,3])
      #   Hanami::CygUtils::Kernel.Array(set)              # => [1,2,3]
      #
      #   response = Response.new(200, {}, 'hello')
      #   Hanami::CygUtils::Kernel.Array(response)         # => [200, {}, "hello"]
      def self.Array(arg)
        super(arg).dup.tap do |a|
          a.flatten!
          a.compact!
          a.uniq!
        end
      end

      # Coerces the argument to be a Set.
      #
      # @param arg [Object] the input
      #
      # @return [Set] the result of the coercion
      #
      # @raise [TypeError] if arg doesn't implement #respond_to?
      #
      # @since 0.1.1
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.Set(nil)              # => #<Set: {}>
      #   Hanami::CygUtils::Kernel.Set(true)             # => #<Set: {true}>
      #   Hanami::CygUtils::Kernel.Set(false)            # => #<Set: {false}>
      #   Hanami::CygUtils::Kernel.Set(1)                # => #<Set: {1}>
      #   Hanami::CygUtils::Kernel.Set([1])              # => #<Set: {1}>
      #   Hanami::CygUtils::Kernel.Set([1, 1])           # => #<Set: {1}>
      #   Hanami::CygUtils::Kernel.Set([1, [2]])         # => #<Set: {1, [2]}>
      #   Hanami::CygUtils::Kernel.Set([1, [2, nil]])    # => #<Set: {1, [2, nil]}>
      #   Hanami::CygUtils::Kernel.Set({a: 1})           # => #<Set: {[:a, 1]}>
      #
      # @example Set Interface
      #   require 'securerandom'
      #   require 'hanami/cyg_utils/kernel'
      #
      #   UuidSet = Class.new do
      #     def initialize(*uuids)
      #       @uuids = uuids
      #     end
      #
      #     def to_set
      #       Set.new.tap do |set|
      #         @uuids.each {|uuid| set.add(uuid) }
      #       end
      #     end
      #   end
      #
      #   uuids = UuidSet.new(SecureRandom.uuid)
      #   Hanami::CygUtils::Kernel.Set(uuids)
      #     # => #<Set: {"daa798b4-630c-4e11-b29d-92f0b1c7d075"}>
      #
      # @example Unchecked Exceptions
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.Set(BasicObject.new) # => TypeError
      def self.Set(arg)
        if arg.respond_to?(:to_set)
          arg.to_set
        else
          Set.new(::Kernel.Array(arg))
        end
      rescue NoMethodError
        raise TypeError.new("can't convert #{inspect_type_error(arg)}into Set")
      end

      # Coerces the argument to be a Hash.
      #
      # @param arg [Object] the input
      #
      # @return [Hash] the result of the coercion
      #
      # @raise [TypeError] if arg can't be coerced
      #
      # @since 0.1.1
      #
      # @see http://www.ruby-doc.org/core/Kernel.html#method-i-Hash
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.Hash(nil)                 # => {}
      #   Hanami::CygUtils::Kernel.Hash({a: 1})              # => { :a => 1 }
      #   Hanami::CygUtils::Kernel.Hash([[:a, 1]])           # => { :a => 1 }
      #   Hanami::CygUtils::Kernel.Hash(Set.new([[:a, 1]]))  # => { :a => 1 }
      #
      # @example Hash Interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Room = Class.new do
      #     def initialize(*args)
      #       @args = args
      #     end
      #
      #     def to_h
      #       Hash[*@args]
      #     end
      #   end
      #
      #   Record = Class.new do
      #     def initialize(attributes = {})
      #       @attributes = attributes
      #     end
      #
      #     def to_hash
      #       @attributes
      #     end
      #   end
      #
      #   room = Room.new(:key, 123456)
      #   Hanami::CygUtils::Kernel.Hash(room)        # => { :key => 123456 }
      #
      #   record = Record.new(name: 'L')
      #   Hanami::CygUtils::Kernel.Hash(record)      # => { :name => "L" }
      #
      # @example Unchecked Exceptions
      #   require 'hanami/cyg_utils/kernel'
      #
      #   input = BasicObject.new
      #   Hanami::CygUtils::Kernel.Hash(input) # => TypeError
      def self.Hash(arg)
        if arg.respond_to?(:to_h)
          arg.to_h
        else
          super(arg)
        end
      rescue NoMethodError
        raise TypeError.new "can't convert #{inspect_type_error(arg)}into Hash"
      end

      # Coerces the argument to be an Integer.
      #
      # It's similar to Ruby's Kernel.Integer, but it doesn't stop at the first
      # error and raise an exception only when the argument can't be coerced.
      #
      # @param arg [Object] the argument
      #
      # @return [Fixnum] the result of the coercion
      #
      # @raise [TypeError] if the argument can't be coerced
      #
      # @since 0.1.1
      #
      # @see http://www.ruby-doc.org/core/Kernel.html#method-i-Integer
      #
      # @example Basic Usage
      #   require 'bigdecimal'
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.Integer(1)                        # => 1
      #   Hanami::CygUtils::Kernel.Integer(1.2)                      # => 1
      #   Hanami::CygUtils::Kernel.Integer(011)                      # => 9
      #   Hanami::CygUtils::Kernel.Integer(0xf5)                     # => 245
      #   Hanami::CygUtils::Kernel.Integer("1")                      # => 1
      #   Hanami::CygUtils::Kernel.Integer(Rational(0.3))            # => 0
      #   Hanami::CygUtils::Kernel.Integer(Complex(0.3))             # => 0
      #   Hanami::CygUtils::Kernel.Integer(BigDecimal(12.00001))     # => 12
      #   Hanami::CygUtils::Kernel.Integer(176605528590345446089)
      #     # => 176605528590345446089
      #
      #   Hanami::CygUtils::Kernel.Integer(Time.now)                 # => 1396947161
      #
      # @example Integer Interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   UltimateAnswer = Struct.new(:question) do
      #     def to_int
      #       42
      #     end
      #   end
      #
      #   answer = UltimateAnswer.new('The Ultimate Question of Life')
      #   Hanami::CygUtils::Kernel.Integer(answer) # => 42
      #
      # @example Error Handling
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # nil
      #   Kernel.Integer(nil)               # => TypeError
      #   Hanami::CygUtils::Kernel.Integer(nil) # => 0
      #
      #   # float represented as a string
      #   Kernel.Integer("23.4")               # => TypeError
      #   Hanami::CygUtils::Kernel.Integer("23.4") # => 23
      #
      #   # rational represented as a string
      #   Kernel.Integer("2/3")               # => TypeError
      #   Hanami::CygUtils::Kernel.Integer("2/3") # => 2
      #
      #   # complex represented as a string
      #   Kernel.Integer("2.5/1")               # => TypeError
      #   Hanami::CygUtils::Kernel.Integer("2.5/1") # => 2
      #
      # @example Unchecked Exceptions
      #   require 'date'
      #   require 'bigdecimal'
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # Missing #to_int and #to_i
      #   input = OpenStruct.new(color: 'purple')
      #   Hanami::CygUtils::Kernel.Integer(input) # => TypeError
      #
      #   # String that doesn't represent an integer
      #   input = 'hello'
      #   Hanami::CygUtils::Kernel.Integer(input) # => TypeError
      #
      #   # When true
      #   input = true
      #   Hanami::CygUtils::Kernel.Integer(input) # => TypeError
      #
      #   # When false
      #   input = false
      #   Hanami::CygUtils::Kernel.Integer(input) # => TypeError
      #
      #   # When Date
      #   input = Date.today
      #   Hanami::CygUtils::Kernel.Integer(input) # => TypeError
      #
      #   # When DateTime
      #   input = DateTime.now
      #   Hanami::CygUtils::Kernel.Integer(input) # => TypeError
      #
      #   # bigdecimal infinity
      #   input = BigDecimal("Infinity")
      #   Hanami::CygUtils::Kernel.Integer(input) # => TypeError
      #
      #   # bigdecimal NaN
      #   input = BigDecimal("NaN")
      #   Hanami::CygUtils::Kernel.Integer(input) # => TypeError
      #
      #   # big rational
      #   input = Rational(-8) ** Rational(1, 3)
      #   Hanami::CygUtils::Kernel.Integer(input) # => TypeError
      #
      #   # big complex represented as a string
      #   input = Complex(2, 3)
      #   Hanami::CygUtils::Kernel.Integer(input) # => TypeError
      def self.Integer(arg)
        super(arg)
      rescue ArgumentError, TypeError, NoMethodError
        begin
          case arg
          when NilClass, ->(a) { a.respond_to?(:to_i) && numeric?(a) }
            arg.to_i
          else
            raise TypeError.new "can't convert #{inspect_type_error(arg)}into Integer"
          end
        rescue NoMethodError
          raise TypeError.new "can't convert #{inspect_type_error(arg)}into Integer"
        end
      rescue RangeError
        raise TypeError.new "can't convert #{inspect_type_error(arg)}into Integer"
      end

      # Coerces the argument to be a BigDecimal.
      #
      # @param arg [Object] the argument
      #
      # @return [BigDecimal] the result of the coercion
      #
      # @raise [TypeError] if the argument can't be coerced
      #
      # @since 0.3.0
      #
      # @see http://www.ruby-doc.org/stdlib/libdoc/bigdecimal/rdoc/BigDecimal.html
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.BigDecimal(1)                        # => 1
      #   Hanami::CygUtils::Kernel.BigDecimal(1.2)                      # => 1
      #   Hanami::CygUtils::Kernel.BigDecimal(011)                      # => 9
      #   Hanami::CygUtils::Kernel.BigDecimal(0xf5)                     # => 245
      #   Hanami::CygUtils::Kernel.BigDecimal("1")                      # => 1
      #   Hanami::CygUtils::Kernel.BigDecimal(Rational(0.3))            # => 0.3
      #   Hanami::CygUtils::Kernel.BigDecimal(Complex(0.3))             # => 0.3
      #   Hanami::CygUtils::Kernel.BigDecimal(BigDecimal(12.00001))     # => 12.00001
      #   Hanami::CygUtils::Kernel.BigDecimal(176605528590345446089)
      #     # => 176605528590345446089
      #
      # @example BigDecimal Interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   UltimateAnswer = Struct.new(:question) do
      #     def to_d
      #       BigDecimal(42)
      #     end
      #   end
      #
      #   answer = UltimateAnswer.new('The Ultimate Question of Life')
      #   Hanami::CygUtils::Kernel.BigDecimal(answer)
      #     # => #<BigDecimal:7fabfd148588,'0.42E2',9(27)>
      #
      # @example Unchecked exceptions
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # When nil
      #   input = nil
      #   Hanami::CygUtils::Kernel.BigDecimal(nil) # => TypeError
      #
      #   # When true
      #   input = true
      #   Hanami::CygUtils::Kernel.BigDecimal(input) # => TypeError
      #
      #   # When false
      #   input = false
      #   Hanami::CygUtils::Kernel.BigDecimal(input) # => TypeError
      #
      #   # When Date
      #   input = Date.today
      #   Hanami::CygUtils::Kernel.BigDecimal(input) # => TypeError
      #
      #   # When DateTime
      #   input = DateTime.now
      #   Hanami::CygUtils::Kernel.BigDecimal(input) # => TypeError
      #
      #   # When Time
      #   input = Time.now
      #   Hanami::CygUtils::Kernel.BigDecimal(input) # => TypeError
      #
      #   # String that doesn't represent a big decimal
      #   input = 'hello'
      #   Hanami::CygUtils::Kernel.BigDecimal(input) # => TypeError
      #
      #   # Missing #respond_to?
      #   input = BasicObject.new
      #   Hanami::CygUtils::Kernel.BigDecimal(input) # => TypeError
      #
      def self.BigDecimal(arg, precision = ::Float::DIG)
        case arg
        when NilClass # This is only needed by Ruby 2.6
          raise TypeError.new "can't convert #{inspect_type_error(arg)}into BigDecimal"
        when Rational
          arg.to_d(precision)
        when Numeric
          BigDecimal(arg.to_s)
        when ->(a) { a.respond_to?(:to_d) }
          arg.to_d
        else
          ::Kernel.BigDecimal(arg, precision)
        end
      rescue NoMethodError
        raise TypeError.new "can't convert #{inspect_type_error(arg)}into BigDecimal"
      end

      # Coerces the argument to be a Float.
      #
      # It's similar to Ruby's Kernel.Float, but it doesn't stop at the first
      # error and raise an exception only when the argument can't be coerced.
      #
      # @param arg [Object] the argument
      #
      # @return [Float] the result of the coercion
      #
      # @raise [TypeError] if the argument can't be coerced
      #
      # @since 0.1.1
      #
      # @see http://www.ruby-doc.org/core/Kernel.html#method-i-Float
      #
      # @example Basic Usage
      #   require 'bigdecimal'
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.Float(1)                        # => 1.0
      #   Hanami::CygUtils::Kernel.Float(1.2)                      # => 1.2
      #   Hanami::CygUtils::Kernel.Float(011)                      # => 9.0
      #   Hanami::CygUtils::Kernel.Float(0xf5)                     # => 245.0
      #   Hanami::CygUtils::Kernel.Float("1")                      # => 1.0
      #   Hanami::CygUtils::Kernel.Float(Rational(0.3))            # => 0.3
      #   Hanami::CygUtils::Kernel.Float(Complex(0.3))             # => 0.3
      #   Hanami::CygUtils::Kernel.Float(BigDecimal(12.00001))     # => 12.00001
      #   Hanami::CygUtils::Kernel.Float(176605528590345446089)
      #     # => 176605528590345446089.0
      #
      #   Hanami::CygUtils::Kernel.Float(Time.now) # => 397750945.515169
      #
      # @example Float Interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   class Pi
      #     def to_f
      #       3.14
      #     end
      #   end
      #
      #   pi = Pi.new
      #   Hanami::CygUtils::Kernel.Float(pi) # => 3.14
      #
      # @example Error Handling
      #   require 'bigdecimal'
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # nil
      #   Kernel.Float(nil)               # => TypeError
      #   Hanami::CygUtils::Kernel.Float(nil) # => 0.0
      #
      #   # float represented as a string
      #   Kernel.Float("23.4")               # => TypeError
      #   Hanami::CygUtils::Kernel.Float("23.4") # => 23.4
      #
      #   # rational represented as a string
      #   Kernel.Float("2/3")               # => TypeError
      #   Hanami::CygUtils::Kernel.Float("2/3") # => 2.0
      #
      #   # complex represented as a string
      #   Kernel.Float("2.5/1")               # => TypeError
      #   Hanami::CygUtils::Kernel.Float("2.5/1") # => 2.5
      #
      #   # bigdecimal infinity
      #   input = BigDecimal("Infinity")
      #   Hanami::CygUtils::Kernel.Float(input) # => Infinity
      #
      #   # bigdecimal NaN
      #   input = BigDecimal("NaN")
      #   Hanami::CygUtils::Kernel.Float(input) # => NaN
      #
      # @example Unchecked Exceptions
      #   require 'date'
      #   require 'bigdecimal'
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # Missing #to_f
      #   input = OpenStruct.new(color: 'purple')
      #   Hanami::CygUtils::Kernel.Float(input) # => TypeError
      #
      #   # When true
      #   input = true
      #   Hanami::CygUtils::Kernel.Float(input) # => TypeError
      #
      #   # When false
      #   input = false
      #   Hanami::CygUtils::Kernel.Float(input) # => TypeError
      #
      #   # When Date
      #   input = Date.today
      #   Hanami::CygUtils::Kernel.Float(input) # => TypeError
      #
      #   # When DateTime
      #   input = DateTime.now
      #   Hanami::CygUtils::Kernel.Float(input) # => TypeError
      #
      #   # Missing #nil?
      #   input = BasicObject.new
      #   Hanami::CygUtils::Kernel.Float(input) # => TypeError
      #
      #   # String that doesn't represent a float
      #   input = 'hello'
      #   Hanami::CygUtils::Kernel.Float(input) # => TypeError
      #
      #   # big rational
      #   input = Rational(-8) ** Rational(1, 3)
      #   Hanami::CygUtils::Kernel.Float(input) # => TypeError
      #
      #   # big complex represented as a string
      #   input = Complex(2, 3)
      #   Hanami::CygUtils::Kernel.Float(input) # => TypeError
      def self.Float(arg)
        super(arg)
      rescue ArgumentError, TypeError
        begin
          case arg
          when NilClass, ->(a) { a.respond_to?(:to_f) && numeric?(a) }
            arg.to_f
          else
            raise TypeError.new "can't convert #{inspect_type_error(arg)}into Float"
          end
        rescue NoMethodError
          raise TypeError.new "can't convert #{inspect_type_error(arg)}into Float"
        end
      rescue RangeError
        raise TypeError.new "can't convert #{inspect_type_error(arg)}into Float"
      end

      # Coerces the argument to be a String.
      #
      # Identical behavior of Ruby's Kernel.Array, still here because we want
      # to keep the interface consistent
      #
      # @param arg [Object] the argument
      #
      # @return [String] the result of the coercion
      #
      # @raise [TypeError] if the argument can't be coerced
      #
      # @since 0.1.1
      #
      # @see http://www.ruby-doc.org/core/Kernel.html#method-i-String
      #
      # @example Basic Usage
      #   require 'date'
      #   require 'bigdecimal'
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.String('')                            # => ""
      #   Hanami::CygUtils::Kernel.String('ciao')                        # => "ciao"
      #
      #   Hanami::CygUtils::Kernel.String(true)                          # => "true"
      #   Hanami::CygUtils::Kernel.String(false)                         # => "false"
      #
      #   Hanami::CygUtils::Kernel.String(:hanami)                        # => "hanami"
      #
      #   Hanami::CygUtils::Kernel.String(Picture)                       # => "Picture" # class
      #   Hanami::CygUtils::Kernel.String(Hanami)                         # => "Hanami" # module
      #
      #   Hanami::CygUtils::Kernel.String([])                            # => "[]"
      #   Hanami::CygUtils::Kernel.String([1,2,3])                       # => "[1, 2, 3]"
      #   Hanami::CygUtils::Kernel.String(%w[a b c])                     # => "[\"a\", \"b\", \"c\"]"
      #
      #   Hanami::CygUtils::Kernel.String({})                            # => "{}"
      #   Hanami::CygUtils::Kernel.String({a: 1, 'b' => 'c'})            # => "{:a=>1, \"b\"=>\"c\"}"
      #
      #   Hanami::CygUtils::Kernel.String(Date.today)                    # => "2014-04-11"
      #   Hanami::CygUtils::Kernel.String(DateTime.now)                  # => "2014-04-11T10:15:06+02:00"
      #   Hanami::CygUtils::Kernel.String(Time.now)                      # => "2014-04-11 10:15:53 +0200"
      #
      #   Hanami::CygUtils::Kernel.String(1)                             # => "1"
      #   Hanami::CygUtils::Kernel.String(3.14)                          # => "3.14"
      #   Hanami::CygUtils::Kernel.String(013)                           # => "11"
      #   Hanami::CygUtils::Kernel.String(0xc0ff33)                      # => "12648243"
      #
      #   Hanami::CygUtils::Kernel.String(Rational(-22))                 # => "-22/1"
      #   Hanami::CygUtils::Kernel.String(Complex(11, 2))                # => "11+2i"
      #   Hanami::CygUtils::Kernel.String(BigDecimal(7944.2343, 10))     # => "0.79442343E4"
      #   Hanami::CygUtils::Kernel.String(BigDecimal('Infinity'))        # => "Infinity"
      #   Hanami::CygUtils::Kernel.String(BigDecimal('NaN'))             # => "Infinity"
      #
      # @example String interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   SimpleObject = Class.new(BasicObject) do
      #     def to_s
      #       'simple object'
      #     end
      #   end
      #
      #   Isbn = Struct.new(:code) do
      #     def to_str
      #       code.to_s
      #     end
      #   end
      #
      #   simple = SimpleObject.new
      #   isbn   = Isbn.new(123)
      #
      #   Hanami::CygUtils::Kernel.String(simple) # => "simple object"
      #   Hanami::CygUtils::Kernel.String(isbn)   # => "123"
      #
      # @example Comparison with Ruby
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # nil
      #   Kernel.String(nil)               # => ""
      #   Hanami::CygUtils::Kernel.String(nil) # => ""
      #
      # @example Unchecked Exceptions
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # Missing #to_s or #to_str
      #   input = BaseObject.new
      #   Hanami::CygUtils::Kernel.String(input) # => TypeError
      def self.String(arg)
        arg = arg.to_str if arg.respond_to?(:to_str)
        super(arg)
      rescue NoMethodError
        raise TypeError.new "can't convert #{inspect_type_error(arg)}into String"
      end

      # Coerces the argument to be a Date.
      #
      # @param arg [Object] the argument
      #
      # @return [Date] the result of the coercion
      #
      # @raise [TypeError] if the argument can't be coerced
      #
      # @since 0.1.1
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.Date(Date.today)
      #     # => #<Date: 2014-04-17 ((2456765j,0s,0n),+0s,2299161j)>
      #
      #   Hanami::CygUtils::Kernel.Date(DateTime.now)
      #     # => #<Date: 2014-04-17 ((2456765j,0s,0n),+0s,2299161j)>
      #
      #   Hanami::CygUtils::Kernel.Date(Time.now)
      #     # => #<Date: 2014-04-17 ((2456765j,0s,0n),+0s,2299161j)>
      #
      #   Hanami::CygUtils::Kernel.Date('2014-04-17')
      #     # => #<Date: 2014-04-17 ((2456765j,0s,0n),+0s,2299161j)>
      #
      #   Hanami::CygUtils::Kernel.Date('2014-04-17 22:37:15')
      #     # => #<Date: 2014-04-17 ((2456765j,0s,0n),+0s,2299161j)>
      #
      # @example Date Interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   class Christmas
      #     def to_date
      #       Date.parse('Dec, 25')
      #     end
      #   end
      #
      #   Hanami::CygUtils::Kernel.Date(Christmas.new)
      #     # => #<Date: 2014-12-25 ((2457017j,0s,0n),+0s,2299161j)>
      #
      # @example Unchecked Exceptions
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # nil
      #   input = nil
      #   Hanami::CygUtils::Kernel.Date(input) # => TypeError
      #
      #   # Missing #respond_to?
      #   input = BasicObject.new
      #   Hanami::CygUtils::Kernel.Date(input) # => TypeError
      #
      #   # Missing #to_s?
      #   input = BasicObject.new
      #   Hanami::CygUtils::Kernel.Date(input) # => TypeError
      def self.Date(arg)
        if arg.respond_to?(:to_date)
          arg.to_date
        else
          Date.parse(arg.to_s)
        end
      rescue ArgumentError, NoMethodError
        raise TypeError.new "can't convert #{inspect_type_error(arg)}into Date"
      end

      # Coerces the argument to be a DateTime.
      #
      # @param arg [Object] the argument
      #
      # @return [DateTime] the result of the coercion
      #
      # @raise [TypeError] if the argument can't be coerced
      #
      # @since 0.1.1
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.DateTime(3483943)
      #     # => Time.at(3483943).to_datetime
      #     # #<DateTime: 1970-02-10T08:45:43+01:00 ((2440628j,27943s,0n),+3600s,2299161j)>
      #
      #   Hanami::CygUtils::Kernel.DateTime(DateTime.now)
      #     # => #<DateTime: 2014-04-18T09:33:49+02:00 ((2456766j,27229s,690849000n),+7200s,2299161j)>
      #
      #   Hanami::CygUtils::Kernel.DateTime(Date.today)
      #     # => #<DateTime: 2014-04-18T00:00:00+00:00 ((2456766j,0s,0n),+0s,2299161j)>
      #
      #   Hanami::CygUtils::Kernel.Date(Time.now)
      #     # => #<DateTime: 2014-04-18T09:34:49+02:00 ((2456766j,27289s,832907000n),+7200s,2299161j)>
      #
      #   Hanami::CygUtils::Kernel.DateTime('2014-04-18')
      #     # => #<DateTime: 2014-04-18T00:00:00+00:00 ((2456766j,0s,0n),+0s,2299161j)>
      #
      #   Hanami::CygUtils::Kernel.DateTime('2014-04-18 09:35:42')
      #     # => #<DateTime: 2014-04-18T09:35:42+00:00 ((2456766j,34542s,0n),+0s,2299161j)>
      #
      # @example DateTime Interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   class NewYearEve
      #     def to_datetime
      #       DateTime.parse('Jan, 1')
      #     end
      #   end
      #
      #   Hanami::CygUtils::Kernel.Date(NewYearEve.new)
      #     # => #<DateTime: 2014-01-01T00:00:00+00:00 ((2456659j,0s,0n),+0s,2299161j)>
      #
      # @example Unchecked Exceptions
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # When nil
      #   input = nil
      #   Hanami::CygUtils::Kernel.DateTime(input) # => TypeError
      #
      #   # Missing #respond_to?
      #   input = BasicObject.new
      #   Hanami::CygUtils::Kernel.DateTime(input) # => TypeError
      #
      #   # Missing #to_s?
      #   input = BasicObject.new
      #   Hanami::CygUtils::Kernel.DateTime(input) # => TypeError
      def self.DateTime(arg)
        case arg
        when ->(a) { a.respond_to?(:to_datetime) } then arg.to_datetime
        when Numeric then DateTime(Time.at(arg))
        else
          DateTime.parse(arg.to_s)
        end
      rescue ArgumentError, NoMethodError
        raise TypeError.new "can't convert #{inspect_type_error(arg)}into DateTime"
      end

      # Coerces the argument to be a Time.
      #
      # @param arg [Object] the argument
      #
      # @return [Time] the result of the coercion
      #
      # @raise [TypeError] if the argument can't be coerced
      #
      # @since 0.1.1
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.Time(Time.now)
      #     # => 2014-04-18 15:56:39 +0200
      #
      #   Hanami::CygUtils::Kernel.Time(DateTime.now)
      #     # => 2014-04-18 15:56:39 +0200
      #
      #   Hanami::CygUtils::Kernel.Time(Date.today)
      #     # => 2014-04-18 00:00:00 +0200
      #
      #   Hanami::CygUtils::Kernel.Time('2014-04-18')
      #     # => 2014-04-18 00:00:00 +0200
      #
      #   Hanami::CygUtils::Kernel.Time('2014-04-18 15:58:02')
      #     # => 2014-04-18 15:58:02 +0200
      #
      # @example Time Interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   class Epoch
      #     def to_time
      #       Time.at(0)
      #     end
      #   end
      #
      #   Hanami::CygUtils::Kernel.Time(Epoch.new)
      #     # => 1970-01-01 01:00:00 +0100
      #
      # @example Unchecked Exceptions
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # When nil
      #   input = nil
      #   Hanami::CygUtils::Kernel.Time(input) # => TypeError
      #
      #   # Missing #respond_to?
      #   input = BasicObject.new
      #   Hanami::CygUtils::Kernel.Time(input) # => TypeError
      #
      #   # Missing #to_s?
      #   input = BasicObject.new
      #   Hanami::CygUtils::Kernel.Time(input) # => TypeError
      def self.Time(arg)
        case arg
        when ->(a) { a.respond_to?(:to_time) } then arg.to_time
        when Numeric then Time.at(arg)
        else
          Time.parse(arg.to_s)
        end
      rescue ArgumentError, NoMethodError
        raise TypeError.new "can't convert #{inspect_type_error(arg)}into Time"
      end

      # Coerces the argument to be a Boolean.
      #
      # @param arg [Object] the argument
      #
      # @return [true,false] the result of the coercion
      #
      # @raise [TypeError] if the argument can't be coerced
      #
      # @since 0.1.1
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.Boolean(nil)                      # => false
      #   Hanami::CygUtils::Kernel.Boolean(0)                        # => false
      #   Hanami::CygUtils::Kernel.Boolean(1)                        # => true
      #   Hanami::CygUtils::Kernel.Boolean('0')                      # => false
      #   Hanami::CygUtils::Kernel.Boolean('1')                      # => true
      #   Hanami::CygUtils::Kernel.Boolean(Object.new)               # => true
      #
      # @example Boolean Interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Answer = Struct.new(:answer) do
      #     def to_bool
      #       case answer
      #       when 'yes' then true
      #       else false
      #       end
      #     end
      #   end
      #
      #   answer = Answer.new('yes')
      #   Hanami::CygUtils::Kernel.Boolean(answer) # => true
      #
      # @example Unchecked Exceptions
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # Missing #respond_to?
      #   input = BasicObject.new
      #   Hanami::CygUtils::Kernel.Boolean(input) # => TypeError
      def self.Boolean(arg)
        case arg
        when Numeric
          arg.to_i == BOOLEAN_TRUE_INTEGER
        when ::String, CygUtils::String, BOOLEAN_FALSE_STRING
          Boolean(arg.to_i)
        when ->(a) { a.respond_to?(:to_bool) }
          arg.to_bool
        else
          !!arg
        end
      rescue NoMethodError
        raise TypeError.new "can't convert #{inspect_type_error(arg)}into Boolean"
      end

      # Coerces the argument to be a Pathname.
      #
      # @param arg [#to_pathname,#to_str] the argument
      #
      # @return [Pathname] the result of the coercion
      #
      # @raise [TypeError] if the argument can't be coerced
      #
      # @since 0.1.2
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.Pathname(Pathname.new('/path/to')) # => #<Pathname:/path/to>
      #   Hanami::CygUtils::Kernel.Pathname('/path/to')               # => #<Pathname:/path/to>
      #
      # @example Pathname Interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   class HomePath
      #     def to_pathname
      #       Pathname.new Dir.home
      #     end
      #   end
      #
      #   Hanami::CygUtils::Kernel.Pathname(HomePath.new) # => #<Pathname:/Users/luca>
      #
      # @example String Interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   class RootPath
      #     def to_str
      #       '/'
      #     end
      #   end
      #
      #   Hanami::CygUtils::Kernel.Pathname(RootPath.new) # => #<Pathname:/>
      #
      # @example Unchecked Exceptions
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # When nil
      #   input = nil
      #   Hanami::CygUtils::Kernel.Pathname(input) # => TypeError
      #
      #   # Missing #respond_to?
      #   input = BasicObject.new
      #   Hanami::CygUtils::Kernel.Pathname(input) # => TypeError
      def self.Pathname(arg)
        case arg
        when ->(a) { a.respond_to?(:to_pathname) } then arg.to_pathname
        else
          super
        end
      rescue NoMethodError
        raise TypeError.new "can't convert #{inspect_type_error(arg)}into Pathname"
      end

      # Coerces the argument to be a Symbol.
      #
      # @param arg [#to_sym] the argument
      #
      # @return [Symbol] the result of the coercion
      #
      # @raise [TypeError] if the argument can't be coerced
      #
      # @since 0.2.0
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/kernel'
      #
      #   Hanami::CygUtils::Kernel.Symbol(:hello)  # => :hello
      #   Hanami::CygUtils::Kernel.Symbol('hello') # => :hello
      #
      # @example Symbol Interface
      #   require 'hanami/cyg_utils/kernel'
      #
      #   class StatusSymbol
      #     def to_sym
      #       :success
      #     end
      #   end
      #
      #   Hanami::CygUtils::Kernel.Symbol(StatusSymbol.new) # => :success
      #
      # @example Unchecked Exceptions
      #   require 'hanami/cyg_utils/kernel'
      #
      #   # When nil
      #   input = nil
      #   Hanami::CygUtils::Kernel.Symbol(input) # => TypeError
      #
      #   # When empty string
      #   input = ''
      #   Hanami::CygUtils::Kernel.Symbol(input) # => TypeError
      #
      #   # Missing #respond_to?
      #   input = BasicObject.new
      #   Hanami::CygUtils::Kernel.Symbol(input) # => TypeError
      def self.Symbol(arg)
        case arg
        when "" then raise TypeError.new "can't convert #{inspect_type_error(arg)}into Symbol"
        when ->(a) { a.respond_to?(:to_sym) } then arg.to_sym
        else
          raise TypeError.new "can't convert #{inspect_type_error(arg)}into Symbol"
        end
      rescue NoMethodError
        raise TypeError.new "can't convert #{inspect_type_error(arg)}into Symbol"
      end

      # Checks if the given argument is a string representation of a number
      #
      # @param arg [Object] the input
      #
      # @return [TrueClass,FalseClass]
      #
      # @since 0.8.0
      # @api private
      def self.numeric?(arg)
        !(arg.to_s =~ NUMERIC_MATCHER).nil?
      end

      # Returns the most useful type error possible
      #
      # If the object does not respond_to?(:inspect), we return the class, else we
      # return nil. In all cases, this method is tightly bound to callers, as this
      # method appends the required space to make the error message look good.
      #
      # @since 0.4.3
      # @api private
      def self.inspect_type_error(arg)
        (arg.respond_to?(:inspect) ? arg.inspect : arg.to_s) + " "
      rescue NoMethodError
        # missing the #respond_to? method, fall back to returning the class' name
        begin
          arg.class.name + " instance "
        rescue NoMethodError
          # missing the #class method, can't fall back to anything better than nothing
          # Callers will have to guess from their code
          nil
        end
      end

      class << self
        private :inspect_type_error
      end
    end
  end
end
