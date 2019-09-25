# frozen_string_literal: true

# A complete web framework for Ruby
#
# @since 0.1.0
#
# @see http://hanamirb.org
module Hanami
  require "hanami/version"
  # require "hanami/frameworks"
  require "hanami/container" # TODO: get rid of this
  require "hanami/application"
  require "hanami/slice"

  @_mutex = Mutex.new

  def self.application
    @_mutex.synchronize do
      raise "Hanami.application not configured" unless defined?(@_application)

      @_application
    end
  end

  def self.application?
    defined?(@_application) && @_application
  end

  def self.application=(application)
    @_mutex.synchronize do
      # Maybe just warn here?

      # raise "Hanami.application already configured" if defined?(@_application)

      @_application = application
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
