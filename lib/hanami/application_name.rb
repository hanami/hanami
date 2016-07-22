require 'hanami/utils/string'

module Hanami
  # An application name.
  #
  # @since 0.2.1
  class ApplicationName

    # A list of words that are prohibited from forming the application name
    #
    # @since 0.2.1
    RESERVED_WORDS = %w(hanami).freeze

    # Initialize and check against reserved words
    #
    # An application name needs to be translated in quite a few ways:
    # First, it must be checked against a list of reserved words and rejected
    # if it is invalid. Secondly, assuming it is not invalid, it must be able
    # to be output roughly as given, but with the following changes:
    #
    # 1. downcased,
    # 2. with surrounding spaces removed,
    # 3. with internal whitespace rendered as underscores
    # 4. with underscores de-duplicated
    #
    # which is the default output. It must also be transformable into an
    # environment variable.
    #
    # @return [Hanami::ApplicationName] a new instance of the application name
    #
    # @since 0.2.1
    def initialize(name)
      @name = sanitize(name)
      ensure_validity!
    end

    # Returns the cleaned application name.
    #
    # @return [String] the sanitized name
    #
    # @example
    #   ApplicationName.new("my-App ").to_s # => "my_app"
    #
    # @since 0.2.1
    def to_s
      @name
    end

    # @api private
    # @since 0.8.0
    alias_method :to_str, :to_s

    # Returns the application name uppercased with non-alphanumeric characters
    # as underscores.
    #
    # @return [String] the upcased name
    #
    # @example
    #   ApplicationName.new("my-app").to_env_s => "MY_APP"
    #
    # @since 0.2.1
    def to_env_s
      @name.upcase.gsub(/\W/, '_')
    end

    # Returns true if a potential application name matches one of the reserved
    # words.
    #
    # @param name [String] the application name
    # @return [TrueClass, FalseClass] the result of the check
    #
    # @example
    #   Hanami::ApplicationName.invalid?("hanami") # => true
    #
    # @since 0.2.1
    def self.invalid?(name)
      RESERVED_WORDS.include?(name)
    end

    private

    # Raises RuntimeError with explanation if the provided name is invalid.
    #
    # @api private
    # @since 0.2.1
    def ensure_validity!
      if self.class.invalid?(@name)
        raise RuntimeError,
          "application name must not be any one of the following: " +
          RESERVED_WORDS.join(", ")
      end
    end

    # Cleans a string to be a functioning application name.
    #
    # @api private
    # @since 0.2.1
    def sanitize(name)
      Utils::String.new(
        name.strip
      ).underscore.to_s
    end
  end
end
