require 'singleton'
require 'thread'

module RSpec
  module Support
    class Env
      include Singleton

      def self.setup
        instance.__send__(:setup)
      end

      def self.reset
        instance.__send__(:setup)
      end

      def self.env
        instance.to_h
      end

      def self.[](key)
        instance[key]
      end

      def self.[]=(key, value)
        instance[key] = value
      end

      def self.fetch_from_original(key)
        instance.__send__(:original).fetch(key)
      end

      def initialize
        @original = ENV.to_hash
        @mutex    = Mutex.new
        setup
      end

      def [](key)
        synchronize do
          env[key]
        end
      end

      def []=(key, value)
        synchronize do
          env[key] = value
        end
      end

      def to_h
        env.dup
      end

      private

      attr_reader :original, :env

      def setup
        synchronize do
          @env = {}
        end

        self["GEM_ROOT"] = original["GEM_ROOT"]
        self["GEM_HOME"] = original["GEM_HOME"]
        self["GEM_PATH"] = original["GEM_PATH"]
      end

      def synchronize(&blk)
        @mutex.synchronize(&blk)
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    RSpec::Support::Env.setup
  end

  config.after do
    RSpec::Support::Env.reset
  end
end
