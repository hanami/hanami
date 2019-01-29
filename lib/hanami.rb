# frozen_string_literal: true

# A complete web framework for Ruby
#
# @since 0.1.0
#
# @see http://hanamirb.org
module Hanami
  require "hanami/version"
  require "hanami/frameworks"
  require "hanami/container"
  require "hanami/application"

  @_mutex = Mutex.new

  def self.application
    @_mutex.synchronize do
      raise "Hanami application not configured" unless defined?(@_application)

      @_application
    end
  end

  def self.application=(app)
    @_mutex.synchronize do
      raise "Hanami application already configured" if defined?(@_application)

      @_application = app unless app.name.nil?
    end
  end

  def self.app
    @_mutex.synchronize do
      raise "Hanami.app not configured" unless defined?(@_app)

      @_app
    end
  end

  def self.app=(app)
    @_mutex.synchronize do
      raise "Hanami.app already configured" if defined?(@_app)

      @_app = app
    end
  end

  def self.root
    Container.root
  end

  def self.env
    (ENV["HANAMI_ENV"] || "development").to_sym
  end

  def self.env?(*names)
    names.map(&:to_sym).include?(env)
  end

  def self.logger
    Container[:logger]
  end

  def self.boot
    @_mutex.synchronize do
      raise "Hanami application already booted" if defined?(@_booted)

      @_booted = true
    end

    Container.finalize!
    self.app = application.new
  end

  def self.bundler_groups
    [:plugins]
  end
end
