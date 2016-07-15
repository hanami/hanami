module Hanami
  module Assets
    # Requested asset
    #
    # @since x.x.x
    # @api private
    class Asset
      # @since x.x.x
      # @api private
      PUBLIC_DIRECTORY = Hanami.public_directory.join('**', '*').to_s.freeze

      # @since x.x.x
      # @api private
      URL_SEPARATOR = '/'.freeze

      # @since x.x.x
      # @api private
      attr_reader :path

      # @since x.x.x
      # @api private
      attr_reader :config

      # @since x.x.x
      # @api private
      attr_reader :original

      # @since x.x.x
      # @api private
      def initialize(sources, path)
        @path            = path
        @prefix, @config = sources.find { |p, _| path.start_with?(p) }

        if @prefix && @config
          @original = @config.sources.find(@path.sub(@prefix, ''))
        end
      end

      # @since x.x.x
      # @api private
      def precompile?
        original && config
      end

      # @since x.x.x
      # @api private
      def exist?
        return true unless original.nil?

        file_path = path.gsub(URL_SEPARATOR, ::File::SEPARATOR)
        destination = find_asset do |a|
          a.end_with?(file_path)
        end

        !destination.nil?
      end

      private

      # @since x.x.x
      # @api private
      def find_asset
        Dir[PUBLIC_DIRECTORY].find do |asset|
          yield asset unless ::File.directory?(asset)
        end
      end
    end
  end
end
