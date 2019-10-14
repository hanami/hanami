# frozen_string_literal: true

# A complete web framework for Ruby
#
# @since 0.1.0
#
# @see http://hanamirb.org
module Hanami
  require "hanami/version"
  require "hanami/application"
  require "hanami/slice"

  @_mutex = Mutex.new

  # TODO: we're going to need to work out better names for these
  # application/application_class methods, since the application_class is
  # actually the entirety of the application (it's bootable, etc., and anything
  # that _doesn't_ require a web interface, like the CLI, will be using that
  # instead)

  def self.application
    @_mutex.synchronize do
      raise "Hanami.application not configured" unless defined?(@_application)

      @_application
    end
  end

  def self.application_class
    @_mutex.synchronize do
      raise "Hanami.application_class not configured" unless defined?(@_application_class)

      @_application_class
    end
  end

  def self.application=(application)
    @_mutex.synchronize do
      raise "Hanami.application already configured" if defined?(@_application)

      @_application = application
    end
  end

  def self.application_class=(klass)
    @_mutex.synchronize do
      raise "Hanami.application already configured" if defined?(@_application)

      @_application_class = klass
    end
  end

  class << self
    alias app application
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

  # WIP — this could just be removed given we have it in Application now?
  # def self.boot
  #   @_mutex.synchronize do
  #     raise "Hanami application already booted" if defined?(@_booted)

  #     @_booted = true
  #   end

  #   Container.finalize!
  #   # self.application = application_class.new
  # end

  def self.bundler_groups
    [:plugins]
  end
end
