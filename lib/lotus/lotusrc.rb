require 'pathname'
require 'dotenv/parser'

module Lotus
  # Read the .lotusrc file in the root of the application
  #
  # @since 0.3.0
  # @api private
  class Lotusrc
    # Lotusrc name file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc#path_file
    FILE_NAME = '.lotusrc'.freeze

    # Architecture default value
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc#options
    DEFAULT_ARCHITECTURE = 'container'.freeze

    # Architecture key for writing the lotusrc file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc::DEFAULT_OPTIONS
    #
    # @deprecated in 0.6.0
    ARCHITECTURE_KEY = 'architecture'.freeze

    # Test suite default value
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc::DEFAULT_OPTIONS
    DEFAULT_TEST_SUITE = 'minitest'.freeze

    # Test suite key for writing the lotusrc file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc::DEFAULT_OPTIONS
    #
    # @deprecated in 0.6.0
    TEST_KEY = 'test'.freeze

    # Template default value
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc::DEFAULT_OPTIONS
    DEFAULT_TEMPLATE = 'erb'.freeze

    # Template key for writing the lotusrc file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc::DEFAULT_OPTIONS
    #
    # @deprecated in 0.6.0
    TEMPLATE_KEY = 'template'.freeze

    # Default values for writing the lotusrc file
    #
    # @since 0.5.1
    # @api private
    #
    # @see Lotus::Lotusrc#options
    DEFAULT_OPTIONS = {
      architecture: DEFAULT_ARCHITECTURE,
      test: DEFAULT_TEST_SUITE,
      template: DEFAULT_TEMPLATE
    }.freeze

    # Initialize Lotusrc class with application's root and environment options.
    #
    # @param root [Pathname] Application's root
    #
    # @see Lotus::Environment#initialize
    def initialize(root)
      @root = root
    end

    # Read lotusrc file (if exists) and parse it's values or return default.
    #
    # @return [Lotus::Utils::Hash] parsed values
    #
    # @example Default values if file doesn't exist
    #   Lotus::Lotusrc.new(Pathname.new(Dir.pwd)).options
    #    # => { architecture: 'container', test: 'minitest', template: 'erb' }
    #
    # @example Custom values if file doesn't exist
    #   options = { architect: 'application', test: 'rspec', template: 'slim' }
    #   Lotus::Lotusrc.new(Pathname.new(Dir.pwd), options).options
    #    # => { architecture: 'application', test: 'rspec', template: 'slim' }
    def options
      @options ||= symbolize(DEFAULT_OPTIONS.merge(file_options))
    end

    # Check if lotusrc file exists
    #
    # @since 0.3.0
    # @api private
    #
    # @return [Boolean] lotusrc file's path existing
    def exists?
      path_file.exist?
    end

    private

    def symbolize(hash)
      Utils::Hash.new(hash).symbolize!
    end

    def file_options
      symbolize(exists? ? Dotenv::Parser.call(content) : {})
    end

    # Return the lotusrc file's path
    #
    # @since 0.3.0
    # @api private
    #
    # @return [Pathname] lotusrc file's path
    #
    # @see Lotus::Lotusrc::FILE_NAME
    def path_file
      @root.join FILE_NAME
    end

    # Return the content of lotusrc file
    #
    # @since 0.3.0
    # @api private
    #
    # @return [String] content of lotusrc file
    def content
      path_file.read
    end
  end
end
