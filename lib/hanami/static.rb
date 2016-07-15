require 'rack/static'

module Hanami
  # Serve static assets in deployment enviroments (production, staging) where
  # the architecture doesn't include a web server.
  #
  # Web servers like Nginx are the ideal candidate to serve static assets.
  # They are faster than Ruby application servers (eg. Puma) and they should be
  # always preferred for this specific task.
  #
  # But there are some PaaS that don't allow to use web servers in front of Ruby
  # web applications. A classical example is Heroku, which requires the web
  # application to serve static assets.
  #
  # Hanami::Static is designed for this specific scenario.
  #
  # To enable it set the env variable `SERVE_STATIC_ASSETS` on `true`.
  #
  # NOTE: Please remember to precompile the assets at the deploy time with
  # `bundle exec hanami assets precompile`.
  #
  # @since 0.6.0
  # @api private
  #
  # @see http://www.rubydoc.info/gems/rack/Rack/Static
  class Static < ::Rack::Static
    # @since x.x.x
    # @api private
    MAX_AGE      = 60 * 60 * 24 * 365 # One year

    # @since x.x.x
    # @api private
    HEADER_RULES = [[:all, { 'Cache-Control' => "public, max-age=#{MAX_AGE}" }]].freeze

    # @since 0.6.0
    # @api private
    def initialize(app, root: Hanami.public_directory, header_rules: HEADER_RULES)
      super(app, urls: ['/assets'], root: root, header_rules: header_rules)
    end
  end
end
