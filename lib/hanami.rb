require 'thread'
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
  require 'hanami/configuration'

  DEFAULT_PUBLIC_DIRECTORY = 'public'.freeze

  @_mutex = Mutex.new

  def self.configure(&blk)
    @_mutex.synchronize do
      @_configuration = Hanami::Configuration.new(&blk)
    end
  end

  def self.configuration
    @_mutex.synchronize do
      raise "not configured" unless defined?(@_configuration)
      @_configuration
    end
  end

  def self.boot
    Hanami::Application.applications.each(&:new)
  end

  require 'rack/builder'
  class App
    def initialize(configuration)
      @builder = ::Rack::Builder.new
      @routes = Router.new

      configuration.apps do |app, path_prefix|
        @routes.mount(app, at: path_prefix)
      end

      if middleware = Hanami.environment.static_assets_middleware
        @builder.use middleware
      end

      @builder.use Rack::MethodOverride

      @builder.run @routes
    end

    def call(env)
      @builder.call(env)
    end
  end

  def self.app
    App.new(configuration)
  end

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
