require 'lotus/version'
require 'lotus/application'
require 'lotus/container'
require 'lotus/environment'

# A complete web framework for Ruby
#
# @since 0.1.0
#
# @see http://lotusrb.org
module Lotus
  DEFAULT_PUBLIC_DIRECTORY = 'public'.freeze

  # Return root of the project (top level directory).
  #
  # @return [Pathname] root path
  #
  # @since 0.3.2
  #
  # @example
  #   Lotus.root # => #<Pathname:/Users/luca/Code/bookshelf>
  def self.root
    environment.root
  end

  def self.public_directory
    root.join(DEFAULT_PUBLIC_DIRECTORY)
  end

  # Return the current environment
  #
  # @return [String] the current environment
  #
  # @since 0.3.1
  #
  # @see Lotus::Environment#environment
  #
  # @example
  #   Lotus.env => "development"
  def self.env
    environment.environment
  end

  # Check to see if specified environment(s) matches the current environment.
  #
  # If multiple names are given, it returns true, if at least one of them
  # matches the current environment.
  #
  # @return [TrueClass,FalseClass] the result of the check
  #
  # @since 0.3.1
  #
  # @see Lotus.env
  #
  # @example Single name
  #   puts ENV['LOTUS_ENV'] # => "development"
  #
  #   Lotus.env?(:development)  # => true
  #   Lotus.env?('development') # => true
  #
  #   Lotus.env?(:production)   # => false
  #
  # @example Multiple names
  #   puts ENV['LOTUS_ENV'] # => "development"
  #
  #   Lotus.env?(:development, :test)   # => true
  #   Lotus.env?(:production, :staging) # => false
  def self.env?(*names)
    environment.environment?(*names)
  end

  # Return environment
  #
  # @return [Lotus::Environment] environment
  #
  # @api private
  # @since 0.3.2
  def self.environment
    Environment.new
  end
end
