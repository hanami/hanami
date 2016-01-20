require 'hanami/utils/basic_object'

module Hanami::Mailer
  # @since 0.5.0
  # @api private
  class Delivery < ::Hanami::Utils::BasicObject
    # @since 0.5.0
    # @api private
    def initialize(env, &blk)
      @env = env
      instance_eval(&blk)
    end

    # @since 0.5.0
    # @api private
    def to_config
      @config
    end

    # @since 0.5.0
    # @api private
    def test(*args)
      __setup_config(:test, *args)
    end

    private

    # @since 0.5.0
    # @api private
    def method_missing(m, *args)
      __setup_config(m, *args)
    end

    # @since 0.5.0
    # @api private
    def __setup_config(env, *args)
      if env.to_s == @env
        @config = args
      end
    end
  end


  # @since 0.5.0
  # @api private
  module Glue

    # @since 0.5.0
    # @api private
    def delivery(&blk)
      raise ArgumentError unless block_given?
      delivery_method(*Hanami::Mailer::Delivery.new(Hanami.env, &blk).to_config)
    end
  end

  Configuration.class_eval do
    include Glue
  end
end

# @since 0.5.0
# @api private
module Mailers
end

Hanami::Mailer.configure do
  namespace Mailers
end
