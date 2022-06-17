# frozen_string_literal: true

module Hanami
  # @since 2.0.0
  Error = Class.new(StandardError)

  # @since 2.0.0
  ApplicationLoadError = Class.new(Error)

  # @since 2.0.0
  SliceLoadError = Class.new(Error)

  # @since 2.0.0
  ComponentLoadError = Class.new(Error)
end
