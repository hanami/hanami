# frozen_string_literal: true

# A complete web framework for Ruby
#
# @since 0.1.0
#
# @see http://hanamirb.org
module Hanami
  require "hanami/version"
  require "hanami/frameworks"
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
end
