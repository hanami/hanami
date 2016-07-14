module Hanami
  module Assets
    class Asset
      PUBLIC_DIRECTORY = Hanami.public_directory.join('**', '*').to_s.freeze

      # @since x.x.x
      # @api private
      URL_SEPARATOR = '/'.freeze

      attr_reader :path, :config, :original

      def initialize(sources, path)
        @path            = path
        @prefix, @config = sources.find { |p, _| path.start_with?(p) }

        if @prefix && @config
          @original = @config.sources.find(@path.sub(@prefix, ''))
        end
      end

      def precompile?
        original && config
      end

      def exist?
        return true unless original.nil?

        file_path = path.gsub(URL_SEPARATOR, ::File::SEPARATOR)
        destination = find_asset do |a|
          a.end_with?(file_path)
        end

        !destination.nil?
      end

      private

      def find_asset
        Dir[PUBLIC_DIRECTORY].find do |asset|
          yield asset unless ::File.directory?(asset)
        end
      end
    end
  end
end
