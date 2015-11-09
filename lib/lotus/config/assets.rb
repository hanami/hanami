module Lotus
  module Config
    # Assets configuration
    #
    # @since 0.1.0
    # @api private
    class Assets  < Utils::LoadPaths
      DEFAULT_DIRECTORY = 'assets'.freeze

      # Assets source (directory)
      #
      # @since 0.5.0
      # @api private
      class Source
        # @since 0.5.0
        # @api private
        BLANK         = ''.freeze

        # @since 0.5.0
        # @api private
        URL_SEPARATOR = '/'.freeze

        # @since 0.5.0
        # @api private
        attr_reader :urls

        # @since 0.5.0
        # @api private
        attr_reader :root

        # @since 0.5.0
        # @api private
        def initialize(path)
          @path = path.to_s
          @root = @path.sub("#{ Lotus.root }/", BLANK)
          @urls = {}

          Dir.glob("#{ path }/**/*").each do |file|
            next if ::File.directory?(file)

            @urls.store(
              file.sub(@path, BLANK).sub(::File::SEPARATOR, URL_SEPARATOR),
              file.sub("#{ @path }/", BLANK)
            )
          end

          @urls.freeze
        end
      end

      class Sources
        attr_reader :sources

        def initialize
          @sources = []
        end

        def push(*paths)
          @sources.push(*paths)
        end
        alias_method :<<, :push

        def to_a
          @sources
        end
      end

      # @since 0.1.0
      # @api private
      def initialize(configuration)
        @root  = configuration.root
        @sources = Sources.new
        configuration.assets.__apply(@sources)
        @paths = Utils::Kernel.Array(@sources.to_a + [DEFAULT_DIRECTORY])
      end

      # @since 0.5.0
      # @api private
      def for_each_source
        each do |path|
          yield Source.new(path) if path.exist?
        end
      end

      # @since 0.2.0
      # @api private
      def any?
        @paths.any?
      end

      protected
      # @since 0.1.0
      # @api private
      def realpath(path)
        @root.join(path).realpath
      end
    end
  end
end

