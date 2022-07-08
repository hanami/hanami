# frozen_string_literal: true

require_relative "constants"

module Hanami
  # Represents the name of an {App} or {Slice}.
  #
  # @see Slice::ClassMethods#slice_name
  # @see App::ClassMethods#app_name
  #
  # @api public
  # @since 2.0.0
  class SliceName
    # Returns a new SliceName for the slice or app.
    #
    # You must provide an inflector for the manipulation of the name into various formats.
    # This should be given in the form of a Proc that returns the inflector when called.
    # The reason for this is that the inflector may be replaced by the user during the
    # app configuration phase, so the proc should ensure that the current instance
    # of the inflector is returned whenever needed.
    #
    # @param slice [#name] the slice or app object
    # @param inflector [Proc] Proc returning the app's inflector when called
    #
    # @api private
    def initialize(slice, inflector:)
      @slice = slice
      @inflector = inflector
    end

    # Returns the name of the slice as a downcased, underscored string.
    #
    # This is considered the canonical name of the slice.
    #
    # @example
    #   slice_name.name # => "main"
    #
    # @return [String] the slice name
    #
    # @api public
    # @since 2.0.0
    def name
      inflector.underscore(namespace_name)
    end

    # @api public
    # @since 2.0.0
    alias_method :path, :name

    # Returns the name of the slice's module namespace.
    #
    # @example
    #   slice_name.namespace_name # => "Main"
    #
    # @return [String] the namespace name
    #
    # @api public
    # @since 2.0.0
    def namespace_name
      slice_name.split(MODULE_DELIMITER)[0..-2].join(MODULE_DELIMITER)
    end

    # Returns the constant for the slice's module namespace.
    #
    # @example
    #   slice_name.namespace_const # => Main
    #
    # @return [Module] the namespace module constant
    #
    # @api public
    # @since 2.0.0
    def namespace_const
      inflector.constantize(namespace_name)
    end

    # @api public
    # @since 2.0.0
    alias_method :namespace, :namespace_const

    # @api public
    # @since 2.0.0
    alias_method :to_s, :name

    # Returns the name of a slice as a downcased, underscored symbol.
    #
    # @example
    #   slice_name.name # => :main
    #
    # @return [Symbol] the slice name
    #
    # @see name, to_s
    #
    # @api public
    # @since 2.0.0
    def to_sym
      name.to_sym
    end

    private

    def slice_name
      @slice.name
    end

    # The inflector is callable to allow for it to be configured/replaced after this
    # object has been initialized
    def inflector
      @inflector.()
    end
  end
end
