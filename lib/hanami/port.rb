# frozen_string_literal: true

module Hanami
  # @since 2.0.1
  # @api private
  module Port
    # @since 2.0.1
    # @api private
    DEFAULT = 2300

    # @since 2.0.1
    # @api private
    ENV_VAR = "HANAMI_PORT"

    # @since 2.0.1
    # @api private
    def self.call(value, env = ENV.fetch(ENV_VAR, nil))
      return Integer(value) if !value.nil? && !default?(value)
      return Integer(env) unless env.nil?
      return Integer(value) unless value.nil?

      DEFAULT
    end

    # @since 2.0.1
    # @api private
    def self.call!(value)
      return if default?(value)

      ENV[ENV_VAR] = value.to_s
    end

    # @since 2.0.1
    # @api private
    def self.default?(value)
      value.to_i == DEFAULT
    end

    class << self
      # @since 2.0.1
      # @api private
      alias_method :[], :call
    end
  end
end
