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
    end
  end
end