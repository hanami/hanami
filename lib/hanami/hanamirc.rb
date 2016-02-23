require 'pathname'
require 'hanami/utils/hash'

module Hanami
  # Read the .hanamirc file in the root of the application
  #
  # @since 0.3.0
  # @api private
  class Hanamirc
    # Hanamirc name file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Hanami::Hanamirc#path_file
    FILE_NAME = '.hanamirc'.freeze

    # Architecture default value
    #
    # @since 0.3.0
    # @api private
    #
    # @see Hanami::Hanamirc#options
    DEFAULT_ARCHITECTURE = 'container'.freeze

    # Application architecture value
    #
    # @since 0.6.0
    # @api private
    APP_ARCHITECTURE = 'app'.freeze

    # Architecture key for writing the hanamirc file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Hanami::Hanamirc::DEFAULT_OPTIONS
    ARCHITECTURE_KEY = 'architecture'.freeze

    # Test suite default value
    #
    # @since 0.3.0
    # @api private
    #
    # @see Hanami::Hanamirc::DEFAULT_OPTIONS
    DEFAULT_TEST_SUITE = 'minitest'.freeze

    # Test suite key for writing the hanamirc file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Hanami::Hanamirc::DEFAULT_OPTIONS
    TEST_KEY = 'test'.freeze

    # Template default value
    #
    # @since 0.3.0
    # @api private
    #
    # @see Hanami::Hanamirc::DEFAULT_OPTIONS
    DEFAULT_TEMPLATE = 'erb'.freeze

    # Template key for writing the hanamirc file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Hanami::Hanamirc::DEFAULT_OPTIONS
    TEMPLATE_KEY = 'template'.freeze

    # Default values for writing the hanamirc file
    #
    # @since 0.5.1
    # @api private
    #
    # @see Hanami::Hanamirc#options
    DEFAULT_OPTIONS = Utils::Hash.new({
      ARCHITECTURE_KEY => DEFAULT_ARCHITECTURE,
      TEST_KEY         => DEFAULT_TEST_SUITE,
      TEMPLATE_KEY     => DEFAULT_TEMPLATE
    }).symbolize!.freeze

    # Key/value separator in hanamirc file
    #
    # @since 0.8.0
    # @api private
    SEPARATOR = '='.freeze

    # Initialize Hanamirc class with application's root and environment options.
    #
    # @param root [Pathname] Application's root
    #
    # @see Hanami::Environment#initialize
    def initialize(root)
      @root = root
    end

    # Read hanamirc file (if exists) and parse it's values or return default.
    #
    # @return [Hanami::Utils::Hash] parsed values
    #
    # @example Default values if file doesn't exist
    #   Hanami::Hanamirc.new(Pathname.new(Dir.pwd)).options
    #    # => { architecture: 'container', test: 'minitest', template: 'erb' }
    #
    # @example Custom values if file doesn't exist
    #   options = { architect: 'application', test: 'rspec', template: 'slim' }
    #   Hanami::Hanamirc.new(Pathname.new(Dir.pwd), options).options
    #    # => { architecture: 'application', test: 'rspec', template: 'slim' }
    def options
      @options ||= symbolize(DEFAULT_OPTIONS.merge(file_options))
    end

    # Check if hanamirc file exists
    #
    # @since 0.3.0
    # @api private
    #
    # @return [Boolean] hanamirc file's path existing
    def exists?
      path_file.exist?
    end

    private

    def symbolize(hash)
      Utils::Hash.new(hash).symbolize!
    end

    def file_options
      symbolize(exists? ? parse_file(path_file) : {})
    end

    # Read hanamirc file and parse it's values
    #
    # @since 0.8.0
    # @api private
    #
    # @return [Hash] hanamirc parsed values
    def parse_file(path)
      {}.tap do |hash|
        File.readlines(path).each do |line|
          key, value = line.split(SEPARATOR)
          hash[key] = value.strip
        end
      end
    end

    # Return the hanamirc file's path
    #
    # @since 0.3.0
    # @api private
    #
    # @return [Pathname] hanamirc file's path
    #
    # @see Hanami::Hanamirc::FILE_NAME
    def path_file
      @root.join FILE_NAME
    end
  end
end
