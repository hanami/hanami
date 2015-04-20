require 'lotus/version'
require 'lotus/application'
require 'lotus/container'
require 'lotus/logger'
require 'lotus/environment'

# A complete web framework for Ruby
#
# @since 0.1.0
#
# @see http://lotusrb.org
module Lotus

  # Return the current environment
  # @since x.x.x
  #
  # @example Lotus.env => "development"

  def self.env
    Environment.new.environment
  end

  # Check to see if specified environment matches the current environment
  # @since x.x.x
  #
  # @example Lotus.env?(:development) => true

  def self.env?(*names)
    Environment.new.environment?(*names)
  end
end
