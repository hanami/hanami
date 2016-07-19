require 'hanami/version'
require 'hanami/application'
require 'hanami/container'
require 'hanami/environment'
require 'hanami/server'

# A complete web framework for Ruby
#
# @since 0.1.0
#
# @see http://hanamirb.org
module Hanami
  DEFAULT_PUBLIC_DIRECTORY = 'public'.freeze

  # Return root of the project (top level directory).
  #
  # @return [Pathname] root path
  #
  # @since 0.3.2
  #
  # @example
  #   Hanami.root # => #<Pathname:/Users/luca/Code/bookshelf>
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
  # @see Hanami::Environment#environment
  #
  # @example
  #   Hanami.env => "development"
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
  # @see Hanami.env
  #
  # @example Single name
  #   puts ENV['HANAMI_ENV'] # => "development"
  #
  #   Hanami.env?(:development)  # => true
  #   Hanami.env?('development') # => true
  #
  #   Hanami.env?(:production)   # => false
  #
  # @example Multiple names
  #   puts ENV['HANAMI_ENV'] # => "development"
  #
  #   Hanami.env?(:development, :test)   # => true
  #   Hanami.env?(:production, :staging) # => false
  def self.env?(*names)
    environment.environment?(*names)
  end

  # Return environment
  #
  # @return [Hanami::Environment] environment
  #
  # @api private
  # @since 0.3.2
  def self.environment
    Environment.new
  end
end
