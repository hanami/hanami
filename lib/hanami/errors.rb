# frozen_string_literal: true

module Hanami
  # Base class for all Hanami errors.
  #
  # @api public
  # @since 2.0.0
  Error = Class.new(StandardError)

  # Error raised when {Hanami::App} fails to load.
  #
  # @api public
  # @since 2.0.0
  AppLoadError = Class.new(Error)

  # Error raised when an {Hanami::Slice} fails to load.
  #
  # @api public
  # @since 2.0.0
  SliceLoadError = Class.new(Error)

  # Error raised when an individual component fails to load.
  #
  # @api public
  # @since 2.0.0
  ComponentLoadError = Class.new(Error)

  # Error raised when unsupported middleware configuration is given.
  #
  # @see Hanami::Slice::Routing::Middleware::Stack#use
  #
  # @api public
  # @since 2.0.0
  UnsupportedMiddlewareSpecError = Class.new(Error)
end
