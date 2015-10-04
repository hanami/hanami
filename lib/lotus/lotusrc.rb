require 'pathname'
require 'dotenv/parser'

module Lotus
  # Create and read the .lotusrc file in the root of the application
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
    # @see Lotus::Lotusrc#read
    DEFAULT_ARCHITECTURE = 'container'.freeze

    # Architecture key for writing the lotusrc file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc#read
    ARCHITECTURE_KEY = 'architecture'.freeze

    # Test suite default value
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc#read
    DEFAULT_TEST_SUITE = 'minitest'.freeze

    # Test suite key for writing the lotusrc file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc#read
    TEST_KEY = 'test'.freeze

    # Template default value
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc#read
    DEFAULT_TEMPLATE = 'erb'.freeze

    # Template key for writing the lotusrc file
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc#read
    TEMPLATE_KEY = 'template'.freeze

    # Initialize Lotusrc class with application's root and enviroment options.
    # Create the lotusrc file if it doesn't exist in the root given.
    #
    # @param root [Pathname] Application's root
    # @param options [Hash] Environment's options
    #
    # @see Lotus::Environment#initialize
    def initialize(root, options = {})
      @root    = root
      @options = options

      # NOTE this line is here in order to auto-upgrade applications generated
      # with lotusrb < 0.3.0. Consider to remove it in the future.
      create
    end

    # Read lotusrc file and parse it's values.
    #
    # @return [Lotus::Utils::Hash] parsed values
    #
    # @example Default values if file doesn't exist
    #   Lotus::Lotusrc.new(Pathname.new(Dir.pwd)).read
    #    # => { architecture: 'container', test: 'minitest', template: 'erb' }
    #
    # @example Custom values if file doesn't exist
    #   options = { architect: 'application', test: 'rspec', template: 'slim' }
    #   Lotus::Lotusrc.new(Pathname.new(Dir.pwd), options).read
    #    # => { architecture: 'application', test: 'rspec', template: 'slim' }
    def read
      if exists?
        Utils::Hash.new(
          Dotenv::Parser.call(content)
        ).symbolize!
      end
    end

    private

    # Create lotusrc file if exists
    #
    # @since 0.3.0
    # @api private
    #
    # @see Lotus::Lotusrc::DEFAULT_ARCHITECTURE
    # @see Lotus::Lotusrc::ARCHITECTURE_KEY
    # @see Lotus::Lotusrc::DEFAULT_TEST_SUITE
    # @see Lotus::Lotusrc::TEST_KEY
    # @see Lotus::Lotusrc::DEFAULT_TEMPLATE
    # @see Lotus::Lotusrc::TEMPLATE_KEY
    def create
      unless exists?
        rcfile = File.new(path_file, "w")
        rcfile.puts "#{ ARCHITECTURE_KEY }=#{ @options.fetch(:architecture, DEFAULT_ARCHITECTURE) }"
        rcfile.puts "#{ TEST_KEY }=#{ @options.fetch(:test, DEFAULT_TEST_SUITE) }"
        rcfile.puts "#{ TEMPLATE_KEY }=#{ @options.fetch(:template, DEFAULT_TEMPLATE) }"
        rcfile.close
      end
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
