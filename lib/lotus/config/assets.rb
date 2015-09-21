module Lotus
  module Config
    # Assets configuration
    #
    # @since 0.1.0
    # @api private
    class Assets  < Utils::LoadPaths
      DEFAULT_DIRECTORY = 'public'.freeze

      # Assets source (directory)
      #
      # @since x.x.x
      # @api private
      class Source
        # @since x.x.x
        # @api private
        BLANK         = ''.freeze

        # @since x.x.x
        # @api private
        URL_SEPARATOR = '/'.freeze

        # @since x.x.x
        # @api private
        attr_reader :urls

        # @since x.x.x
        # @api private
        attr_reader :root

        # @since x.x.x
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

      # @since 0.1.0
      # @api private
      def initialize(root)
        @root  = root
        @paths = Array(DEFAULT_DIRECTORY)
      end

      # @since x.x.x
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

