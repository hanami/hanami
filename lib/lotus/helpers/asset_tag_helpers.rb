require 'lotus/helpers'

module Lotus
  module Helpers
    # The helper methods for using assets such as images, audio, video, etc.
    #
    # @since 0.6.0
    # @api public
    module AssetTagHelpers
      include Lotus::Helpers::HtmlHelper

      # Creates a img tag. Takes the asset path as the first parameter.
      # Alt attribute is auto-calculated as the titleized path of the asset.
      # Any other parameter will be output as an attribute of the img tag.
      #
      # @since 0.6.0
      # @api public
      #
      # @example Usage in view.
      #
      #   module Web::Views::Home
      #     include Lotus::View
      #
      #     def avatar(user)
      #       image("user_#{user.id}_avatar", id: user.id, class: 'user-avatar')
      #     end
      #   end
      #
      #   This method will output:
      #   => <img src='/assets/user_1_avatar' alt='User 1 avatar' id='1' class='user-avatar'>
      #
      #
      def image(source, options = {})
        options[:src] = asset_path(source)
        options[:alt] ||= Lotus::Utils::String.new(::File.basename(source, File.extname(source))).titleize

        html.img(options)
      end

      def asset_path(source)
        "/assets/#{source}" # To be implemented
      end

      # Generates a video tag for the given arguments.
      #
      # @raise [ArgumentError] if the signature isn't respected
      # @since x.x.x
      # @api public
      #
      # @example Basic usage
      #   <%= video('movie.mp4') %>
      #     # => <video src="/assets/movie.mp4"></video>
      #
      # @example HTML attributes
      #   <%= video('movie.mp4', autoplay: true, controls: true) %>
      #     # => <video src="/assets/movie.mp4" autoplay="autoplay" controls="controls"></video>
      #
      # @example Fallback Content
      #   <%=
      #     video('movie.mp4') do
      #       "Your browser does not support the video tag"
      #     end
      #   %>
      #     # => <video src="/assets/movie.mp4">\nYour browser does not support the video tag\n</video>
      #
      # @example Tracks
      #   <%=
      #     video('movie.mp4') do
      #       track kind: 'captions', src: view.asset_path('movie.en.vtt'), srclang: 'en', label: 'English'
      #     end
      #   %>
      #     # => <video src="/assets/movie.mp4">\n<track kind="captions" src="/assets/movie.en.vtt" srclang="en" label="English">\n</video>
      #
      # @example Sources
      #   <%=
      #     video do
      #       text "Your browser does not support the video tag"
      #       source src: view.asset_path('movie.mp4'), type: 'video/mp4'
      #       source src: view.asset_path('movie.ogg'), type: 'video/ogg'
      #     end
      #   %>
      #     # => <video>\nYour browser does not support the video tag\n<source src="/assets/movie.mp4" type="video/mp4">\n<source src="/assets/movie.ogg" type="video/ogg">\n</video>
      #
      # @example Without any argument
      #   <%= video %>
      #     # => ArgumentError
      #
      # @example Without src and without block
      #   <%= video(content: true) %>
      #     # => ArgumentError
      def video(src = nil, options = {}, &blk)
        options ||= {}

        if src.respond_to?(:to_hash)
          options = src.to_hash
        elsif src
          options[:src] = asset_path(src)
        end

        if !options[:src] && !block_given?
          raise ArgumentError.new('You should provide a source via `src` option or with a `source` HTML tag')
        end

        html.video(blk, options)
      end
    end
  end
end