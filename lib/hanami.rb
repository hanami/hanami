# frozen_string_literal: true

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
  # @return [Hanami::App] the loaded app class
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

  APP_PATH = "config/app.rb"
  private_constant :APP_PATH

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

  def self.app?
    instance_variable_defined?(:@_app)
  end

  def self.app=(klass)
    @_mutex.synchronize do
      if instance_variable_defined?(:@_app)
        raise AppLoadError, "Hanami.app is already configured."
      end

      @_app = klass unless klass.name.nil?
    end
  end

  def self.env
    ENV.fetch("HANAMI_ENV") { ENV.fetch("RACK_ENV", "development") }.to_sym
  end

  def self.env?(*names)
    names.map(&:to_sym).include?(env)
  end

  def self.logger
    app[:logger]
  end

  def self.prepare
    app.prepare
  end

  def self.boot
    app.boot
  end

  def self.shutdown
    app.shutdown
  end

  def self.bundled?(gem_name)
    @_mutex.synchronize do
      @_bundled[gem_name] ||= begin
        gem(gem_name)
        true
      rescue Gem::LoadError
        false
      end
    end
  end

  def self.bundler_groups
    [:plugins]
  end

  require_relative "hanami/version"
  require_relative "hanami/errors"
  require_relative "hanami/extensions"
  require_relative "hanami/app"
end
