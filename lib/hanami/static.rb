require 'rack/static'

module Hanami
  class Static < ::Rack::Static
    HEADER_RULES = [[:all, { 'Cache-Control' => 'public, max-age=31536000' }]].freeze

    def initialize(app, root: Hanami.public_directory, header_rules: HEADER_RULES)
      super(app, urls: ['/assets'], root: root, header_rules: header_rules)
    end
  end
end
