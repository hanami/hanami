# frozen_string_literal: true

require_relative "hanami/constants"

# A complete web framework for Ruby
#
# @since 0.1.0
#
# @see http://hanamirb.org
module Hanami
  @_mutex = Mutex.new
  @_bundled = {}

  # Finds and loads the Hanami app file (`config/app.rb`).
  #
  # Raises an exception if the app file cannot be found.
  #
  # @return [app] the loaded app class
  #
  # @api public
  # @since 2.0.0
  def self.setup(raise_exception: true)
    return app if app?

    app_path = self.app_path

    if app_path
      require(app_path)
      app
    elsif raise_exception
      raise(
        AppLoadError,
        "Could not locate your Hanami app file.\n\n" \
        "Your app file should be at `config/app.rb` in your project's root directory."
      )
    end
  end

  # Returns the Hamami app class.
  #
  # To ensure your Hanami app is loaded, run {.setup} (or `require "hanami/setup"`) first.
  #
  # @return [Hanami::App] the app class
  #
  # @raise [AppLoadError] if the app has not been loaded
  #
  # @see .setup
  #
  # @api public
  # @since 2.0.0
  def self.app
    @_mutex.synchronize do
      unless defined?(@_app)
        raise AppLoadError,
              "Hanami.app is not yet configured. " \
              "You may need to `require \"hanami/setup\"` to load your config/app.rb file."
      end

      @_app
    end
  end

  # Returns true if the Hanami app class has been loaded.
  #
  # @return [Boolean]
  #
  # @api public
  # @since 2.0.0
  def self.app?
    instance_variable_defined?(:@_app)
  end

  # @api private
  # @since 2.0.0
  def self.app=(klass)
    @_mutex.synchronize do
      if instance_variable_defined?(:@_app)
        raise AppLoadError, "Hanami.app is already configured."
      end

      @_app = klass unless klass.name.nil?
    end
  end

  # Finds and returns the absolute path for the Hanami app file (`config/app.rb`).
  #
  # Searches within the given directory, then searches upwards through parent directories until the
  # app file can be found.
  #
  # @param dir [String] The directory from which to start searching. Defaults to the current
  #   directory.
  #
  # @return [String, nil] the app file path, or nil if not found.
  #
  # @api public
  # @since 2.0.0
  def self.app_path(dir = Dir.pwd)
    dir = Pathname(dir).expand_path
    path = dir.join(APP_PATH)

    if path.file?
      path.to_s
    elsif !dir.root?
      app_path(dir.parent)
    end
  end

  # Returns the Hanami app environment as loaded from the `HANAMI_ENV` environment variable.
  #
  # @example
  #   Hanami.env # => :development
  #
  # @return [Symbol] the environment name
  #
  # @api public
  # @since 2.0.0
  def self.env
    ENV.fetch("HANAMI_ENV") { ENV.fetch("RACK_ENV", "development") }.to_sym
  end

  # Returns true if {.env} matches any of the given names
  #
  # @example
  #   Hanami.env # => :development
  #   Hanami.env?(:development, :test) # => true
  #
  # @param names [Array<Symbol>] the environment names to check
  #
  # @return [Boolean]
  #
  # @api public
  # @since 2.0.0
  def self.env?(*names)
    names.map(&:to_sym).include?(env)
  end

  # @api private
  def self.logger
    app[:logger]
  end

  # Prepares the Hanami app.
  #
  # @see App::ClassMethods#prepare
  #
  # @api public
  # @since 2.0.0
  def self.prepare
    app.prepare
  end

  # Boots the Hanami app.
  #
  # @see App::ClassMethods#boot
  #
  # @api public
  # @since 2.0.0
  def self.boot
    app.boot
  end

  # Shuts down the Hanami app.
  #
  # @see App::ClassMethods#shutdown
  #
  # @api public
  # @since 2.0.0
  def self.shutdown
    app.shutdown
  end

  # @api private
  # @since 2.0.0
  def self.bundled?(gem_name)
    @_mutex.synchronize do
      @_bundled[gem_name] ||= begin
        gem(gem_name)
      rescue Gem::LoadError
        false
      end
    end
  end

  # @api private
  def self.bundler_groups
    [:plugins]
  end

  require_relative "hanami/version"
  require_relative "hanami/errors"
  require_relative "hanami/extensions"
  require_relative "hanami/app"
end
