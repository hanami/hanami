require 'hanami/utils/file_list'

module Hanami
  # @api private
  module Assets
    # Requested asset
    #
    # @since 0.8.0
    # @api private
    class Asset
      # @since 0.8.0
      # @api private
      PUBLIC_DIRECTORY = Hanami.public_directory.join('**', '*').to_s.freeze

      # @since 0.8.0
      # @api private
      URL_SEPARATOR = '/'.freeze

      # @since 0.8.0
      # @api private
      attr_reader :path

      # @since 0.8.0
      # @api private
      attr_reader :config

      # @since 0.8.0
      # @api private
      attr_reader :original

      # @since 0.8.0
      # @api private
      def initialize(sources, path)
        @path            = path
        @prefix, @config = sources.find { |p, _| path.start_with?(p) }

        if @prefix && @config
          @original = @config.sources.find(@path.sub(@prefix, ''))
        end
      end

      # @since 0.8.0
      # @api private
      def precompile?
        original && config
      end

      # @since 0.8.0
      # @api private
      def exist?
        return true unless original.nil?

        file_path = path.tr(URL_SEPARATOR, ::File::SEPARATOR)
        destination = find_asset do |a|
          a.end_with?(file_path)
        end

        !destination.nil?
      end

      private

      # @since 0.8.0
      # @api private
      def find_asset
        Utils::FileList[PUBLIC_DIRECTORY].find do |asset|
          yield asset unless ::File.directory?(asset)
        end
      end
    end
  end
end
