# frozen_string_literal: true

require "uri"
require "hanami/view"

# rubocop:disable Metrics/ModuleLength

module Hanami
  module Helpers
    # HTML assets helpers
    #
    # Inject these helpers in a view
    #
    # @since 0.1.0
    #
    # @see http://www.rubydoc.info/gems/hanami-helpers/Hanami/Helpers/HtmlHelper
    module AssetsHelper
      # @since 0.1.0
      # @api private
      NEW_LINE_SEPARATOR = "\n"

      # @since 0.1.0
      # @api private
      WILDCARD_EXT = ".*"

      # @since 0.1.0
      # @api private
      JAVASCRIPT_EXT = ".js"

      # @since 0.1.0
      # @api private
      STYLESHEET_EXT = ".css"

      # @since 0.1.0
      # @api private
      JAVASCRIPT_MIME_TYPE = "text/javascript"

      # @since 0.1.0
      # @api private
      STYLESHEET_MIME_TYPE = "text/css"

      # @since 0.1.0
      # @api private
      FAVICON_MIME_TYPE = "image/x-icon"

      # @since 0.1.0
      # @api private
      STYLESHEET_REL = "stylesheet"

      # @since 0.1.0
      # @api private
      FAVICON_REL = "shortcut icon"

      # @since 0.1.0
      # @api private
      DEFAULT_FAVICON = "favicon.ico"

      # @since 0.3.0
      # @api private
      CROSSORIGIN_ANONYMOUS = "anonymous"

      # @since 0.3.0
      # @api private
      ABSOLUTE_URL_MATCHER = URI::DEFAULT_PARSER.make_regexp

      # @since 1.1.0
      # @api private
      QUERY_STRING_MATCHER = /\?/

      include Hanami::View::Helpers::TagHelper

      # Generate `script` tag for given source(s)
      #
      # It accepts one or more strings representing the name of the asset, if it
      # comes from the application or third party gems. It also accepts strings
      # representing absolute URLs in case of public CDN (eg. jQuery CDN).
      #
      # If the "fingerprint mode" is on, `src` is the fingerprinted
      # version of the relative URL.
      #
      # If the "CDN mode" is on, the `src` is an absolute URL of the
      # application CDN.
      #
      # If the "subresource integrity mode" is on, `integriy` is the
      # name of the algorithm, then a hyphen, then the hash value of the file.
      # If more than one algorithm is used, they"ll be separated by a space.
      #
      # @param sources [Array<String>] one or more assets by name or absolute URL
      #
      # @return [Hanami::View::HTML::SafeString] the markup
      #
      # @raise [Hanami::Assets::MissingManifestAssetError] if `fingerprint` or
      # `subresource_integrity` modes are on and the javascript file is missing
      # from the manifest
      #
      # @since 0.1.0
      #
      # @see Hanami::Assets::Helpers#path
      #
      # @example Single Asset
      #
      #   <%= js "application" %>
      #
      #   # <script src="/assets/application.js" type="text/javascript"></script>
      #
      # @example Multiple Assets
      #
      #   <%= js "application", "dashboard" %>
      #
      #   # <script src="/assets/application.js" type="text/javascript"></script>
      #   # <script src="/assets/dashboard.js" type="text/javascript"></script>
      #
      # @example Asynchronous Execution
      #
      #   <%= js "application", async: true %>
      #
      #   # <script src="/assets/application.js" type="text/javascript" async="async"></script>
      #
      # @example Subresource Integrity
      #
      #   <%= js "application" %>
      #
      #   # <script src="/assets/application-28a6b886de2372ee3922fcaf3f78f2d8.js"
      #   #         type="text/javascript" integrity="sha384-oqVu...Y8wC" crossorigin="anonymous"></script>
      #
      # @example Subresource Integrity for 3rd Party Scripts
      #
      #   <%= js "https://example.com/assets/example.js", integrity: "sha384-oqVu...Y8wC" %>
      #
      #   # <script src="https://example.com/assets/example.js" type="text/javascript"
      #   #         integrity="sha384-oqVu...Y8wC" crossorigin="anonymous"></script>
      #
      # @example Deferred Execution
      #
      #   <%= js "application", defer: true %>
      #
      #   # <script src="/assets/application.js" type="text/javascript" defer="defer"></script>
      #
      # @example Absolute URL
      #
      #   <%= js "https://code.jquery.com/jquery-2.1.4.min.js" %>
      #
      #   # <script src="https://code.jquery.com/jquery-2.1.4.min.js" type="text/javascript"></script>
      #
      # @example Fingerprint Mode
      #
      #   <%= js "application" %>
      #
      #   # <script src="/assets/application-28a6b886de2372ee3922fcaf3f78f2d8.js" type="text/javascript"></script>
      #
      # @example CDN Mode
      #
      #   <%= js "application" %>
      #
      #   # <script src="https://assets.bookshelf.org/assets/application-28a6b886de2372ee3922fcaf3f78f2d8.js"
      #   #         type="text/javascript"></script>
      def javascript_tag(*source_paths, **options)
        options = options.reject { |k, _| k.to_sym == :src }

        _safe_tags(*source_paths) do |source|
          attributes = {
            src: _typed_path(source, JAVASCRIPT_EXT),
            type: JAVASCRIPT_MIME_TYPE
          }
          attributes.merge!(options)

          if _context.assets.subresource_integrity? || attributes.include?(:integrity)
            attributes[:integrity] ||= _subresource_integrity_value(source, JAVASCRIPT_EXT)
            attributes[:crossorigin] ||= CROSSORIGIN_ANONYMOUS
          end

          tag.script(**attributes).to_s
        end
      end

      # Generate `link` tag for given source(s)
      #
      # It accepts one or more strings representing the name of the asset, if it
      # comes from the application or third party gems. It also accepts strings
      # representing absolute URLs in case of public CDN (eg. Bootstrap CDN).
      #
      # If the "fingerprint mode" is on, `href` is the fingerprinted
      # version of the relative URL.
      #
      # If the "CDN mode" is on, the `href` is an absolute URL of the
      # application CDN.
      #
      # If the "subresource integrity mode" is on, `integriy` is the
      # name of the algorithm, then a hyphen, then the hashed value of the file.
      # If more than one algorithm is used, they"ll be separated by a space.
      #
      # @param sources [Array<String>] one or more assets by name or absolute URL
      #
      # @return [Hanami::View::HTML::SafeString] the markup
      #
      # @raise [Hanami::Assets::MissingManifestAssetError] if `fingerprint` or
      # `subresource_integrity` modes are on and the stylesheet file is missing
      # from the manifest
      #
      # @since 0.1.0
      #
      # @see Hanami::Assets::Helpers#path
      #
      # @example Single Asset
      #
      #   <%= css "application" %>
      #
      #   # <link href="/assets/application.css" type="text/css" rel="stylesheet">
      #
      # @example Multiple Assets
      #
      #   <%= css "application", "dashboard" %>
      #
      #   # <link href="/assets/application.css" type="text/css" rel="stylesheet">
      #   # <link href="/assets/dashboard.css" type="text/css" rel="stylesheet">
      #
      # @example Subresource Integrity
      #
      #   <%= css "application" %>
      #
      #   # <link href="/assets/application-28a6b886de2372ee3922fcaf3f78f2d8.css"
      #   #       type="text/css" integrity="sha384-oqVu...Y8wC" crossorigin="anonymous"></script>
      #
      # @example Subresource Integrity for 3rd Party Assets
      #
      #   <%= css "https://example.com/assets/example.css", integrity: "sha384-oqVu...Y8wC" %>
      #
      #   # <link href="https://example.com/assets/example.css"
      #   #       type="text/css" rel="stylesheet" integrity="sha384-oqVu...Y8wC" crossorigin="anonymous"></script>
      #
      # @example Absolute URL
      #
      #   <%= css "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" %>
      #
      #   # <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css"
      #   #       type="text/css" rel="stylesheet">
      #
      # @example Fingerprint Mode
      #
      #   <%= css "application" %>
      #
      #   # <link href="/assets/application-28a6b886de2372ee3922fcaf3f78f2d8.css" type="text/css" rel="stylesheet">
      #
      # @example CDN Mode
      #
      #   <%= css "application" %>
      #
      #   # <link href="https://assets.bookshelf.org/assets/application-28a6b886de2372ee3922fcaf3f78f2d8.css"
      #   #       type="text/css" rel="stylesheet">
      def stylesheet_link_tag(*source_paths, **options)
        options = options.reject { |k, _| k.to_sym == :href }

        _safe_tags(*source_paths) do |source_path|
          attributes = {
            href: _typed_path(source_path, STYLESHEET_EXT),
            type: STYLESHEET_MIME_TYPE,
            rel: STYLESHEET_REL
          }
          attributes.merge!(options)

          if _context.assets.subresource_integrity? || attributes.include?(:integrity)
            attributes[:integrity] ||= _subresource_integrity_value(source_path, STYLESHEET_EXT)
            attributes[:crossorigin] ||= CROSSORIGIN_ANONYMOUS
          end

          tag.link(**attributes).to_s
        end
      end

      # Generate `img` tag for given source
      #
      # It accepts one string representing the name of the asset, if it comes
      # from the application or third party gems. It also accepts string
      # representing absolute URLs in case of public CDN (eg. Bootstrap CDN).
      #
      # `alt` Attribute is auto generated from `src`.
      # You can specify a different value, by passing the `:src` option.
      #
      # If the "fingerprint mode" is on, `src` is the fingerprinted
      # version of the relative URL.
      #
      # If the "CDN mode" is on, the `src` is an absolute URL of the
      # application CDN.
      #
      # @param source [String] asset name or absolute URL
      # @param options [Hash] HTML 5 attributes
      #
      # @return [Hanami::View::HTML::SafeString] the markup
      #
      # @raise [Hanami::Assets::MissingManifestAssetError] if `fingerprint` or
      # `subresource_integrity` modes are on and the image file is missing
      # from the manifest
      #
      # @since 0.1.0
      #
      # @see Hanami::Assets::Helpers#path
      #
      # @example Basic Usage
      #
      #   <%= image "logo.png" %>
      #
      #   # <img src="/assets/logo.png" alt="Logo">
      #
      # @example Custom alt Attribute
      #
      #   <%= image "logo.png", alt: "Application Logo" %>
      #
      #   # <img src="/assets/logo.png" alt="Application Logo">
      #
      # @example Custom HTML Attributes
      #
      #   <%= image "logo.png", id: "logo", class: "image" %>
      #
      #   # <img src="/assets/logo.png" alt="Logo" id="logo" class="image">
      #
      # @example Absolute URL
      #
      #   <%= image "https://example-cdn.com/images/logo.png" %>
      #
      #   # <img src="https://example-cdn.com/images/logo.png" alt="Logo">
      #
      # @example Fingerprint Mode
      #
      #   <%= image "logo.png" %>
      #
      #   # <img src="/assets/logo-28a6b886de2372ee3922fcaf3f78f2d8.png" alt="Logo">
      #
      # @example CDN Mode
      #
      #   <%= image "logo.png" %>
      #
      #   # <img src="https://assets.bookshelf.org/assets/logo-28a6b886de2372ee3922fcaf3f78f2d8.png" alt="Logo">
      def image_tag(source, options = {})
        options = options.reject { |k, _| k.to_sym == :src }
        attributes = {
          src: asset_url(source),
          alt: _context.inflector.humanize(::File.basename(source, WILDCARD_EXT))
        }
        attributes.merge!(options)

        tag.img(**attributes)
      end

      # Generate `link` tag application favicon.
      #
      # If no argument is given, it assumes `favico.ico` from the application.
      #
      # It accepts one string representing the name of the asset.
      #
      # If the "fingerprint mode" is on, `href` is the fingerprinted version
      # of the relative URL.
      #
      # If the "CDN mode" is on, the `href` is an absolute URL of the
      # application CDN.
      #
      # @param source [String] asset name
      # @param options [Hash] HTML 5 attributes
      #
      # @return [Hanami::View::HTML::SafeString] the markup
      #
      # @raise [Hanami::Assets::MissingManifestAssetError] if `fingerprint` or
      # `subresource_integrity` modes are on and the favicon is file missing
      # from the manifest
      #
      # @since 0.1.0
      #
      # @see Hanami::Assets::Helpers#path
      #
      # @example Basic Usage
      #
      #   <%= favicon %>
      #
      #   # <link href="/assets/favicon.ico" rel="shortcut icon" type="image/x-icon">
      #
      # @example Custom Path
      #
      #   <%= favicon "fav.ico" %>
      #
      #   # <link href="/assets/fav.ico" rel="shortcut icon" type="image/x-icon">
      #
      # @example Custom HTML Attributes
      #
      #   <%= favicon "favicon.ico", id: "fav" %>
      #
      #   # <link id: "fav" href="/assets/favicon.ico" rel="shortcut icon" type="image/x-icon">
      #
      # @example Fingerprint Mode
      #
      #   <%= favicon %>
      #
      #   # <link href="/assets/favicon-28a6b886de2372ee3922fcaf3f78f2d8.ico" rel="shortcut icon" type="image/x-icon">
      #
      # @example CDN Mode
      #
      #   <%= favicon %>
      #
      #   # <link href="https://assets.bookshelf.org/assets/favicon-28a6b886de2372ee3922fcaf3f78f2d8.ico"
      #           rel="shortcut icon" type="image/x-icon">
      def favicon_link_tag(source = DEFAULT_FAVICON, options = {})
        options = options.reject { |k, _| k.to_sym == :href }

        attributes = {
          href: asset_url(source),
          rel: FAVICON_REL,
          type: FAVICON_MIME_TYPE
        }
        attributes.merge!(options)

        tag.link(**attributes)
      end

      # Generate `video` tag for given source
      #
      # It accepts one string representing the name of the asset, if it comes
      # from the application or third party gems. It also accepts string
      # representing absolute URLs in case of public CDN (eg. Bootstrap CDN).
      #
      # Alternatively, it accepts a block that allows to specify one or more
      # sources via the `source` tag.
      #
      # If the "fingerprint mode" is on, `src` is the fingerprinted
      # version of the relative URL.
      #
      # If the "CDN mode" is on, the `src` is an absolute URL of the
      # application CDN.
      #
      # @param source [String] asset name or absolute URL
      # @param options [Hash] HTML 5 attributes
      #
      # @return [Hanami::View::HTML::SafeString] the markup
      #
      # @raise [Hanami::Assets::MissingManifestAssetError] if `fingerprint` or
      # `subresource_integrity` modes are on and the video file is missing
      # from the manifest
      #
      # @raise [ArgumentError] if source isn"t specified both as argument or
      #   tag inside the given block
      #
      # @since 0.1.0
      #
      # @see Hanami::Assets::Helpers#path
      #
      # @example Basic Usage
      #
      #   <%= video "movie.mp4" %>
      #
      #   # <video src="/assets/movie.mp4"></video>
      #
      # @example Absolute URL
      #
      #   <%= video "https://example-cdn.com/assets/movie.mp4" %>
      #
      #   # <video src="https://example-cdn.com/assets/movie.mp4"></video>
      #
      # @example Custom HTML Attributes
      #
      #   <%= video("movie.mp4", autoplay: true, controls: true) %>
      #
      #   # <video src="/assets/movie.mp4" autoplay="autoplay" controls="controls"></video>
      #
      # @example Fallback Content
      #
      #   <%=
      #     video("movie.mp4") do
      #       "Your browser does not support the video tag"
      #     end
      #   %>
      #
      #   # <video src="/assets/movie.mp4">
      #   #  Your browser does not support the video tag
      #   # </video>
      #
      # @example Tracks
      #
      #   <%=
      #     video("movie.mp4") do
      #       tag.track(kind: "captions", src: asset_url("movie.en.vtt"),
      #             srclang: "en", label: "English")
      #     end
      #   %>
      #
      #   # <video src="/assets/movie.mp4">
      #   #   <track kind="captions" src="/assets/movie.en.vtt" srclang="en" label="English">
      #   # </video>
      #
      # @example Without Any Argument
      #
      #   <%= video %>
      #
      #   # ArgumentError
      #
      # @example Without src And Without Block
      #
      #   <%= video(content: true) %>
      #
      #   # ArgumentError
      #
      # @example Fingerprint Mode
      #
      #   <%= video "movie.mp4" %>
      #
      #   # <video src="/assets/movie-28a6b886de2372ee3922fcaf3f78f2d8.mp4"></video>
      #
      # @example CDN Mode
      #
      #   <%= video "movie.mp4" %>
      #
      #   # <video src="https://assets.bookshelf.org/assets/movie-28a6b886de2372ee3922fcaf3f78f2d8.mp4"></video>
      def video_tag(source = nil, options = {}, &blk)
        options = _source_options(source, options, &blk)
        tag.video(**options, &blk)
      end

      # Generate `audio` tag for given source
      #
      # It accepts one string representing the name of the asset, if it comes
      # from the application or third party gems. It also accepts string
      # representing absolute URLs in case of public CDN (eg. Bootstrap CDN).
      #
      # Alternatively, it accepts a block that allows to specify one or more
      # sources via the `source` tag.
      #
      # If the "fingerprint mode" is on, `src` is the fingerprinted
      # version of the relative URL.
      #
      # If the "CDN mode" is on, the `src` is an absolute URL of the
      # application CDN.
      #
      # @param source [String] asset name or absolute URL
      # @param options [Hash] HTML 5 attributes
      #
      # @return [Hanami::View::HTML::SafeString] the markup
      #
      # @raise [Hanami::Assets::MissingManifestAssetError] if `fingerprint` or
      # `subresource_integrity` modes are on and the audio file is missing
      # from the manifest
      #
      # @raise [ArgumentError] if source isn"t specified both as argument or
      #   tag inside the given block
      #
      # @since 0.1.0
      #
      # @see Hanami::Assets::Helpers#path
      #
      # @example Basic Usage
      #
      #   <%= audio "song.ogg" %>
      #
      #   # <audio src="/assets/song.ogg"></audio>
      #
      # @example Absolute URL
      #
      #   <%= audio "https://example-cdn.com/assets/song.ogg" %>
      #
      #   # <audio src="https://example-cdn.com/assets/song.ogg"></audio>
      #
      # @example Custom HTML Attributes
      #
      #   <%= audio("song.ogg", autoplay: true, controls: true) %>
      #
      #   # <audio src="/assets/song.ogg" autoplay="autoplay" controls="controls"></audio>
      #
      # @example Fallback Content
      #
      #   <%=
      #     audio("song.ogg") do
      #       "Your browser does not support the audio tag"
      #     end
      #   %>
      #
      #   # <audio src="/assets/song.ogg">
      #   #  Your browser does not support the audio tag
      #   # </audio>
      #
      # @example Tracks
      #
      #   <%=
      #     audio("song.ogg") do
      #       tag.track(kind: "captions", src: asset_url("song.pt-BR.vtt"),
      #             srclang: "pt-BR", label: "Portuguese")
      #     end
      #   %>
      #
      #   # <audio src="/assets/song.ogg">
      #   #   <track kind="captions" src="/assets/song.pt-BR.vtt" srclang="pt-BR" label="Portuguese">
      #   # </audio>
      #
      # @example Without Any Argument
      #
      #   <%= audio %>
      #
      #   # ArgumentError
      #
      # @example Without src And Without Block
      #
      #   <%= audio(controls: true) %>
      #
      #   # ArgumentError
      #
      # @example Fingerprint Mode
      #
      #   <%= audio "song.ogg" %>
      #
      #   # <audio src="/assets/song-28a6b886de2372ee3922fcaf3f78f2d8.ogg"></audio>
      #
      # @example CDN Mode
      #
      #   <%= audio "song.ogg" %>
      #
      #   # <audio src="https://assets.bookshelf.org/assets/song-28a6b886de2372ee3922fcaf3f78f2d8.ogg"></audio>
      def audio_tag(source = nil, options = {}, &blk)
        options = _source_options(source, options, &blk)
        tag.audio(**options, &blk)
      end

      # It generates the relative or absolute URL for the given asset.
      # It automatically decides if it has to use the relative or absolute
      # depending on the configuration and current environment.
      #
      # Absolute URLs are returned as they are.
      #
      # It can be the name of the asset, coming from the sources or third party
      # gems.
      #
      # If Fingerprint mode is on, it returns the fingerprinted path of the source
      #
      # If CDN mode is on, it returns the absolute URL of the asset.
      #
      # @param source [String] the asset name
      #
      # @return [String] the asset path
      #
      # @raise [Hanami::Assets::MissingManifestAssetError] if `fingerprint` or
      # `subresource_integrity` modes are on and the asset is missing
      # from the manifest
      #
      # @since 0.1.0
      #
      # @example Basic Usage
      #
      #   <%= asset_url "application.js" %>
      #
      #   # "/assets/application.js"
      #
      # @example Alias
      #
      #   <%= asset_url "application.js" %>
      #
      #   # "/assets/application.js"
      #
      # @example Absolute URL
      #
      #   <%= asset_url "https://code.jquery.com/jquery-2.1.4.min.js" %>
      #
      #   # "https://code.jquery.com/jquery-2.1.4.min.js"
      #
      # @example Fingerprint Mode
      #
      #   <%= asset_url "application.js" %>
      #
      #   # "/assets/application-28a6b886de2372ee3922fcaf3f78f2d8.js"
      #
      # @example CDN Mode
      #
      #   <%= asset_url "application.js" %>
      #
      #   # "https://assets.bookshelf.org/assets/application-28a6b886de2372ee3922fcaf3f78f2d8.js"
      def asset_url(source_path)
        return source_path if _absolute_url?(source_path)

        _context.assets[source_path].url
      end

      private

      # @since 0.1.0
      # @api private
      def _safe_tags(*source_paths, &blk)
        ::Hanami::View::HTML::SafeString.new(
          source_paths.map(&blk).join(NEW_LINE_SEPARATOR)
        )
      end

      # @since 2.1.0
      # @api private
      def _typed_path(source, ext)
        source = "#{source}#{ext}" if _append_extension?(source, ext)
        asset_url(source)
      end

      # @api private
      def _subresource_integrity_value(source_path, ext)
        return if _absolute_url?(source_path)

        source_path = "#{source_path}#{ext}" unless /#{Regexp.escape(ext)}\z/.match?(source_path)
        _context.assets[source_path].sri
      end

      # @since 0.1.0
      # @api private
      def _absolute_url?(source)
        ABSOLUTE_URL_MATCHER.match(source)
      end

      # @since 1.2.0
      # @api private
      def _crossorigin?(source)
        return false unless _absolute_url?(source)

        _context.assets.crossorigin?(source)
      end

      # @since 0.1.0
      # @api private
      def _source_options(src, options, &blk)
        options ||= {}

        if src.respond_to?(:to_hash)
          options = src.to_hash
        elsif src
          options[:src] = asset_url(src)
        end

        if !options[:src] && !blk
          raise ArgumentError.new("You should provide a source via `src` option or with a `source` HTML tag")
        end

        options
      end

      # @since 1.1.0
      # @api private
      def _append_extension?(source, ext)
        source !~ QUERY_STRING_MATCHER && source !~ /#{Regexp.escape(ext)}\z/
      end
    end
  end
end

# rubocop:enable Metrics/ModuleLength
