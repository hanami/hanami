# frozen_string_literal: true

# A complete web framework for Ruby
#
# @since 0.1.0
#
# @see http://hanamirb.org
module Hanami
  @_mutex = Mutex.new
  @_bundled = {}

  # @api private
  def self.setup
    return if app?

    require_relative "hanami/detect_app"
    app_path = DetectApp.call

    if app_path
      require app_path
    else
      raise(
        Hanami::AppLoadError, \
        "Could not locate your Hanami app file.\n\n" \
        "Your app file should be at `config/app.rb` in your project's root directory."
      )
    end
  end

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
    defined?(@_app)
  end

  def self.app=(klass)
    @_mutex.synchronize do
      if defined?(@_app)
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
