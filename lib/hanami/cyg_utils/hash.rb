# frozen_string_literal: true

require "hanami/cyg_utils/duplicable"
require "transproc"

module Hanami
  module CygUtils
    # Hash on steroids
    # @since 0.1.0
    #
    class Hash
      # @since 0.6.0
      # @api private
      #
      # @see Hanami::CygUtils::Hash#deep_dup
      # @see Hanami::CygUtils::Duplicable
      DUPLICATE_LOGIC = proc do |value|
        case value
        when Hash
          value.deep_dup
        when ::Hash
          Hash.new(value).deep_dup.to_h
        end
      end.freeze

      extend Transproc::Registry
      import Transproc::HashTransformations

      # Symbolize the given hash
      #
      # @param input [::Hash] the input
      #
      # @return [::Hash] the symbolized hash
      #
      # @since 1.0.1
      #
      # @see .deep_symbolize
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/hash'
      #
      #   hash = Hanami::CygUtils::Hash.symbolize("foo" => "bar", "baz" => {"a" => 1})
      #     # => {:foo=>"bar", :baz=>{"a"=>1}}
      #
      #   hash.class
      #     # => Hash
      def self.symbolize(input)
        self[:symbolize_keys].call(input)
      end

      # Performs deep symbolize on the given hash
      #
      # @param input [::Hash] the input
      #
      # @return [::Hash] the deep symbolized hash
      #
      # @since 1.0.1
      #
      # @see .symbolize
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/hash'
      #
      #   hash = Hanami::CygUtils::Hash.deep_symbolize("foo" => "bar", "baz" => {"a" => 1})
      #     # => {:foo=>"bar", :baz=>{a:=>1}}
      #
      #   hash.class
      #     # => Hash
      def self.deep_symbolize(input)
        self[:deep_symbolize_keys].call(input)
      end

      # Stringifies the given hash
      #
      # @param input [::Hash] the input
      #
      # @return [::Hash] the stringified hash
      #
      # @since 1.0.1
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/hash'
      #
      #   hash = Hanami::CygUtils::Hash.stringify(foo: "bar", baz: {a: 1})
      #     # => {"foo"=>"bar", "baz"=>{:a=>1}}
      #
      #   hash.class
      #     # => Hash
      def self.stringify(input)
        self[:stringify_keys].call(input)
      end

      # Deeply stringifies the given hash
      #
      # @param input [::Hash] the input
      #
      # @return [::Hash] the deep stringified hash
      #
      # @since 1.1.1
      #
      # @example Basic Usage
      #   require "hanami/cyg_utils/hash"
      #
      #   hash = Hanami::CygUtils::Hash.deep_stringify(foo: "bar", baz: {a: 1})
      #     # => {"foo"=>"bar", "baz"=>{"a"=>1}}
      #
      #   hash.class
      #     # => Hash
      def self.deep_stringify(input)
        input.each_with_object({}) do |(key, value), output|
          output[key.to_s] =
            case value
            when ::Hash
              deep_stringify(value)
            when Array
              value.map do |item|
                item.is_a?(::Hash) ? deep_stringify(item) : item
              end
            else
              value
            end
        end
      end

      # Deep duplicates hash values
      #
      # The output of this function is a deep duplicate of the input.
      # Any further modification on the input, won't be reflected on the output
      # and viceversa.
      #
      # @param input [::Hash] the input
      #
      # @return [::Hash] the deep duplicate of input
      #
      # @since 1.0.1
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/hash'
      #
      #   input  = { "a" => { "b" => { "c" => [1, 2, 3] } } }
      #   output = Hanami::CygUtils::Hash.deep_dup(input)
      #     # => {"a"=>{"b"=>{"c"=>[1,2,3]}}}
      #
      #   output.class
      #     # => Hash
      #
      #
      #
      #   # mutations on input aren't reflected on output
      #
      #   input["a"]["b"]["c"] << 4
      #   output.dig("a", "b", "c")
      #     # => [1, 2, 3]
      #
      #
      #
      #   # mutations on output aren't reflected on input
      #
      #   output["a"].delete("b")
      #   input
      #     # => {"a"=>{"b"=>{"c"=>[1,2,3,4]}}}
      def self.deep_dup(input)
        input.each_with_object({}) do |(k, v), result|
          result[k] = case v
                      when ::Hash
                        deep_dup(v)
                      else
                        Duplicable.dup(v)
                      end
        end
      end

      # Deep serializes given object into a `Hash`
      #
      # Please note that the returning `Hash` will use symbols as keys.
      #
      # @param input [#to_hash] the input
      #
      # @return [::Hash] the deep serialized hash
      #
      # @since 1.1.0
      #
      # @example Basic Usage
      #   require 'hanami/cyg_utils/hash'
      #   require 'ostruct'
      #
      #   class Data < OpenStruct
      #     def to_hash
      #       to_h
      #     end
      #   end
      #
      #   input = Data.new("foo" => "bar", baz => [Data.new(hello: "world")])
      #
      #   Hanami::CygUtils::Hash.deep_serialize(input)
      #     # => {:foo=>"bar", :baz=>[{:hello=>"world"}]}
      def self.deep_serialize(input)
        input.to_hash.each_with_object({}) do |(key, value), output|
          output[key.to_sym] =
            case value
            when ->(h) { h.respond_to?(:to_hash) }
              deep_serialize(value)
            when Array
              value.map do |item|
                item.respond_to?(:to_hash) ? deep_serialize(item) : item
              end
            else
              value
            end
        end
      end

      # Initialize the hash
      #
      # @param hash [#to_h] the value we want to use to initialize this instance
      # @param blk [Proc] define the default value
      #
      # @return [Hanami::CygUtils::Hash] self
      #
      # @since 0.1.0
      # @deprecated
      #
      # @see http://www.ruby-doc.org/core/Hash.html#method-c-5B-5D
      #
      # @example Passing a Hash
      #   require 'hanami/cyg_utils/hash'
      #
      #   hash = Hanami::CygUtils::Hash.new('l' => 23)
      #   hash['l'] # => 23
      #
      # @example Passing a block for default
      #   require 'hanami/cyg_utils/hash'
      #
      #   hash = Hanami::CygUtils::Hash.new {|h,k| h[k] = [] }
      #   hash['foo'].push 'bar'
      #
      #   hash.to_h # => { 'foo' => ['bar'] }
      def initialize(hash = {}, &blk)
        @hash = hash.to_hash
        @hash.default_proc = blk if blk
      end

      # Converts in-place all the keys to Symbol instances.
      #
      # @return [Hash] self
      #
      # @since 0.1.0
      # @deprecated Use {Hanami::CygUtils::Hash.symbolize}
      #
      # @example
      #   require 'hanami/cyg_utils/hash'
      #
      #   hash = Hanami::CygUtils::Hash.new 'a' => 23, 'b' => { 'c' => ['x','y','z'] }
      #   hash.symbolize!
      #
      #   hash.keys    # => [:a, :b]
      #   hash.inspect # => { :a => 23, :b => { 'c' => ["x", "y", "z"] } }
      def symbolize!
        keys.each do |k|
          v = delete(k)
          self[k.to_sym] = v
        end

        self
      end

      # Converts in-place all the keys to Symbol instances, nested hashes are converted too.
      #
      # @return [Hash] self
      #
      # @since 1.0.0
      # @deprecated Use {Hanami::CygUtils::Hash.deep_symbolize}
      #
      # @example
      #   require 'hanami/cyg_utils/hash'
      #
      #   hash = Hanami::CygUtils::Hash.new 'a' => 23, 'b' => { 'c' => ['x','y','z'] }
      #   hash.deep_symbolize!
      #
      #   hash.keys    # => [:a, :b]
      #   hash.inspect # => {:a=>23, :b=>{:c=>["x", "y", "z"]}}
      def deep_symbolize!
        keys.each do |k|
          v = delete(k)
          v = self.class.new(v).deep_symbolize! if v.respond_to?(:to_hash)

          self[k.to_sym] = v
        end

        self
      end

      # Converts in-place all the keys to Symbol instances, nested hashes are converted too.
      #
      # @return [Hash] self
      #
      # @since 0.3.2
      # @deprecated Use {Hanami::CygUtils::Hash.stringify}
      #
      # @example
      #   require 'hanami/cyg_utils/hash'
      #
      #   hash = Hanami::CygUtils::Hash.new a: 23, b: { c: ['x','y','z'] }
      #   hash.stringify!
      #
      #   hash.keys    # => [:a, :b]
      #   hash.inspect # => {"a"=>23, "b"=>{"c"=>["x", "y", "z"]}}
      def stringify!
        keys.each do |k|
          v = delete(k)
          v = self.class.new(v).stringify! if v.respond_to?(:to_hash)

          self[k.to_s] = v
        end

        self
      end

      # Returns a deep copy of the current Hanami::CygUtils::Hash
      #
      # @return [Hash] a deep duplicated self
      #
      # @since 0.3.1
      # @deprecated Use {Hanami::CygUtils::Hash.deep_dup}
      #
      # @example
      #   require 'hanami/cyg_utils/hash'
      #
      #   hash = Hanami::CygUtils::Hash.new(
      #     'nil'        => nil,
      #     'false'      => false,
      #     'true'       => true,
      #     'symbol'     => :foo,
      #     'fixnum'     => 23,
      #     'bignum'     => 13289301283 ** 2,
      #     'float'      => 1.0,
      #     'complex'    => Complex(0.3),
      #     'bigdecimal' => BigDecimal('12.0001'),
      #     'rational'   => Rational(0.3),
      #     'string'     => 'foo bar',
      #     'hash'       => { a: 1, b: 'two', c: :three },
      #     'u_hash'     => Hanami::CygUtils::Hash.new({ a: 1, b: 'two', c: :three })
      #   )
      #
      #   duped = hash.deep_dup
      #
      #   hash.class  # => Hanami::CygUtils::Hash
      #   duped.class # => Hanami::CygUtils::Hash
      #
      #   hash.object_id  # => 70147385937100
      #   duped.object_id # => 70147385950620
      #
      #   # unduplicated values
      #   duped['nil']        # => nil
      #   duped['false']      # => false
      #   duped['true']       # => true
      #   duped['symbol']     # => :foo
      #   duped['fixnum']     # => 23
      #   duped['bignum']     # => 176605528590345446089
      #   duped['float']      # => 1.0
      #   duped['complex']    # => (0.3+0i)
      #   duped['bigdecimal'] # => #<BigDecimal:7f9ffe6e2fd0,'0.120001E2',18(18)>
      #   duped['rational']   # => 5404319552844595/18014398509481984)
      #
      #   # it duplicates values
      #   duped['string'].reverse!
      #   duped['string'] # => "rab oof"
      #   hash['string']  # => "foo bar"
      #
      #   # it deeply duplicates Hash, by preserving the class
      #   duped['hash'].class # => Hash
      #   duped['hash'].delete(:a)
      #   hash['hash'][:a]    # => 1
      #
      #   duped['hash'][:b].upcase!
      #   duped['hash'][:b] # => "TWO"
      #   hash['hash'][:b]  # => "two"
      #
      #   # it deeply duplicates Hanami::CygUtils::Hash, by preserving the class
      #   duped['u_hash'].class # => Hanami::CygUtils::Hash
      def deep_dup
        self.class.new.tap do |result|
          @hash.each { |k, v| result[k] = Duplicable.dup(v, &DUPLICATE_LOGIC) }
        end
      end

      # Returns a new array populated with the keys from this hash
      #
      # @return [Array] the keys
      #
      # @since 0.3.0
      # @deprecated
      #
      # @see http://www.ruby-doc.org/core/Hash.html#method-i-keys
      def keys
        @hash.keys
      end

      # Deletes the key-value pair and returns the value from hsh whose key is
      # equal to key.
      #
      # @param key [Object] the key to remove
      #
      # @return [Object,nil] the value hold by the given key, if present
      #
      # @since 0.3.0
      # @deprecated
      #
      # @see http://www.ruby-doc.org/core/Hash.html#method-i-keys
      def delete(key)
        @hash.delete(key)
      end

      # Retrieves the value object corresponding to the key object.
      #
      # @param key [Object] the key
      #
      # @return [Object,nil] the correspoding value, if present
      #
      # @since 0.3.0
      # @deprecated
      #
      # @see http://www.ruby-doc.org/core/Hash.html#method-i-5B-5D
      def [](key)
        @hash[key]
      end

      # Associates the value given by value with the key given by key.
      #
      # @param key [Object] the key to assign
      # @param value [Object] the value to assign
      #
      # @since 0.3.0
      # @deprecated
      #
      # @see http://www.ruby-doc.org/core/Hash.html#method-i-5B-5D-3D
      def []=(key, value)
        @hash[key] = value
      end

      # Returns a Ruby Hash as duplicated version of self
      #
      # @return [::Hash] the hash
      #
      # @since 0.3.0
      # @deprecated
      #
      # @see http://www.ruby-doc.org/core/Hash.html#method-i-to_h
      def to_h
        @hash.each_with_object({}) do |(k, v), result|
          v = v.to_h if v.respond_to?(:to_hash)
          result[k] = v
        end
      end

      alias_method :to_hash, :to_h

      # Converts into a nested array of [ key, value ] arrays.
      #
      # @return [::Array] the array
      #
      # @since 0.3.0
      # @deprecated
      #
      # @see http://www.ruby-doc.org/core/Hash.html#method-i-to_a
      def to_a
        @hash.to_a
      end

      # Equality
      #
      # @return [TrueClass,FalseClass]
      #
      # @since 0.3.0
      # @deprecated
      def ==(other)
        @hash == other.to_h
      end

      alias_method :eql?, :==

      # Returns the hash of the internal @hash
      #
      # @return [Fixnum]
      #
      # @since 0.3.0
      # @deprecated
      def hash
        @hash.hash
      end

      # Returns a string describing the internal @hash
      #
      # @return [String]
      #
      # @since 0.3.0
      # @deprecated
      def inspect
        @hash.inspect
      end

      # Overrides Ruby's method_missing in order to provide ::Hash interface
      #
      # @api private
      # @since 0.3.0
      #
      # @raise [NoMethodError] If doesn't respond to the given method
      def method_missing(method_name, *args, &blk)
        unless respond_to?(method_name)
          raise NoMethodError.new(%(undefined method `#{method_name}' for #{@hash}:#{self.class}))
        end

        h = @hash.__send__(method_name, *args, &blk)
        h = self.class.new(h) if h.is_a?(::Hash)
        h
      end

      # Overrides Ruby's respond_to_missing? in order to support ::Hash interface
      #
      # @api private
      # @since 0.3.0
      def respond_to_missing?(method_name, include_private = false)
        @hash.respond_to?(method_name, include_private)
      end
    end
  end
end
