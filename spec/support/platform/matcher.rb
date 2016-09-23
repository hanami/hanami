require 'hanami/utils/basic_object'

module Platform
  class Matcher
    class Nope < Hanami::Utils::BasicObject
      def or(other, &blk)
        blk.nil? ? other : blk.call # rubocop:disable Performance/RedundantBlockCall
      end

      def method_missing(*) # rubocop:disable Style/MethodMissing
        self.class.new
      end
    end

    def self.match(&blk)
      catch :match do
        new.__send__(:match, &blk)
      end
    end

    def self.match?(os: Os.current, engine: Engine.current)
      catch :match do
        new.os(os).engine(engine) { true }.or(false)
      end
    end

    def initialize
      freeze
    end

    def os(name, &blk)
      return nope unless os?(name)
      block_given? ? resolve(&blk) : yep
    end

    def engine(name, &blk)
      return nope unless engine?(name)
      block_given? ? resolve(&blk) : yep
    end

    def default(&blk)
      resolve(&blk)
    end

    private

    def match(&blk)
      instance_exec(&blk)
    end

    def nope
      Nope.new
    end

    def yep
      self.class.new
    end

    def resolve
      throw :match, yield
    end

    def os?(name)
      Os.os?(name)
    end

    def engine?(name)
      Engine.engine?(name)
    end
  end
end
