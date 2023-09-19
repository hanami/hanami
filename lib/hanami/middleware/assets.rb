# frozen_string_literal: true

require "rack/static"

module Hanami
  module Middleware
    class Assets < Rack::Static
      def initialize(app, options = {}, config: Hanami.app.config)
        root = config.actions.public_directory
        urls = [config.assets.path_prefix]

        defaults = {
          root: root,
          urls: urls
        }

        super(app, defaults.merge(options))
      end
    end
  end
end
