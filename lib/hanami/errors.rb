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

  # Error raised when there are no routes defined.
  #
  # @api public
  # @since 2.4.0
  NoRoutesDefinedError = Class.new(Error)

  # Error raised when unsupported middleware configuration is given.
  #
  # @see Hanami::Slice::Routing::Middleware::Stack#use
  #
  # @api public
  # @since 2.0.0
  UnsupportedMiddlewareSpecError = Class.new(Error)

  # Error raised when Hanami's first-party gems are not all on the same major.minor version.
  #
  # Raised when `hanami` is required. Set the `HANAMI_SKIP_GEM_VERSION_CHECK` environment variable
  # to skip this check.
  #
  # @api public
  # @since 3.1.0
  GemVersionMismatchError = Class.new(Error)
end
