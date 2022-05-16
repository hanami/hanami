# frozen_string_literal: true

require "hanami/utils"

require_relative "hanami/application"
require_relative "hanami/errors"
require_relative "hanami/version"


# A complete web framework for Ruby
#
# @since 0.1.0
#
# @see http://hanamirb.org
module Hanami
  @_mutex = Mutex.new

  def self.application
    @_mutex.synchronize do
      unless defined?(@_application)
        raise ApplicationLoadError,
          "Hanami.application is not yet configured. " \
          "You may need to `require \"hanami/setup\"` to load your config/application.rb file."
      end

      @_application
    end
  end

  def self.application?
    defined?(@_application)
  end

  def self.application=(klass)
    @_mutex.synchronize do
      if defined?(@_application)
        raise ApplicationLoadError, "Hanami.application is already configured."
      end

      @_application = klass unless klass.name.nil?
    end
  end

  def self.rack_app
    application.rack_app
  end

  def self.env
    Hanami::Utils.env
  end

  def self.env?(*names)
    Hanami::Utils.env?(*names)
  end

  def self.logger
    application[:logger]
  end

  def self.prepare
    application.prepare
  end

  def self.boot
    application.boot
  end

  def self.shutdown
    application.shutdown
  end

  def self.bundler_groups
    [:plugins]
  end
end
