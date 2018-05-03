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

    # Project name for writing the hanamirc file
    #
    # @since 0.8.0
    # @api private
    #
    # @see Hanami::Hanamirc#default_options
    PROJECT_NAME = 'project'.freeze

    # Test suite default value
    #
    # @since 0.3.0
    # @api private
    #
    # @see Hanami::Hanamirc#default_options
    DEFAULT_TEST_SUITE = 'rspec'.freeze

    # Test suite key for writing the hanamirc file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Hanami::Hanamirc#default_options
    TEST_KEY = 'test'.freeze

    # Template default value
    #
    # @since 0.3.0
    # @api private
    #
    # @see Hanami::Hanamirc#default_options
    DEFAULT_TEMPLATE = 'erb'.freeze

    # Template key for writing the hanamirc file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Hanami::Hanamirc#default_options
    TEMPLATE_KEY = 'template'.freeze

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
    # @return [::Hash] parsed values
    #
    # @example Default values if file doesn't exist
    #   Hanami::Hanamirc.new(Pathname.new(Dir.pwd)).options
    #    # => { test: 'minitest', template: 'erb' }
    #
    # @example Custom values if file doesn't exist
    #   options = { test: 'rspec', template: 'slim' }
    #   Hanami::Hanamirc.new(Pathname.new(Dir.pwd), options).options
    #    # => { test: 'rspec', template: 'slim' }
    def options
      @options ||= symbolize(default_options.merge(file_options))
    end

    # Default values for writing the hanamirc file
    #
    # @since 0.5.1
    # @api private
    #
    # @see Hanami::Hanamirc#options
    def default_options
      @default_options ||= Utils::Hash.symbolize({
                                           PROJECT_NAME     => project_name,
                                           TEST_KEY         => DEFAULT_TEST_SUITE,
                                           TEMPLATE_KEY     => DEFAULT_TEMPLATE
                                         }).freeze
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

    # @api private
    def symbolize(hash)
      Utils::Hash.symbolize(hash)
    end

    # Returns options from hanamirc file
    #
    # @since 0.6.0
    # @api private
    #
    # @return [Hash] hanamirc parsed values
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

    # Generates a default project name based on the application directory
    #
    # @since 0.8.0
    # @api private
    #
    # @return [String] application_name
    #
    # @see Hanami::Hanamirc::PROJECT_NAME
    def project_name
      ::File.basename(@root)
    end
  end
end
