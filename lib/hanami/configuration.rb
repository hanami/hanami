require 'concurrent'
require 'delegate'
require 'hanami/application'
require 'hanami/utils/class'
require 'hanami/utils/string'

module Hanami
  # @api private
  class Configuration
    # @api private
    class App < SimpleDelegator
      # @api private
      attr_reader :path_prefix

      # @api private
      def initialize(app, path_prefix)
        super(app)
        @path_prefix = path_prefix
      end
    end

    # @api private
    def initialize(&blk)
      @settings = Concurrent::Map.new
      instance_eval(&blk)
    end

    # Mount a Hanami::Application or a Rack app
    #
    # @param app [#call] an application compatible with Rack SPEC
    # @param options [Hash] a set of options
    # @option :at [String] options the mount point
    #
    # @since 0.9.0
    #
    # @example
    #   # config/environment.rb
    #   # ...
    #   Hanami.configure do
    #     mount Web::Application, at: '/'
    #
    #     # ...
    #   end
    def mount(app, options)
      mounted[app] = App.new(app, options.fetch(:at))
    end

    # Configure database
    #
    # @param blk [Proc] the database configuration
    #
    # @see Hanami::Model.configure
    #
    # @example
    #   # config/environment.rb
    #   # ...
    #   Hanami.configure do
    #     model do
    #       adapter :sql, ENV['DATABASE_URL']
    #
    #       migrations 'db/migrations'
    #       schema     'db/schema.sql'
    #     end
    #
    #     # ...
    #   end
    def model(&blk)
      if block_given?
        settings.put_if_absent(:model, blk)
      else
        settings.fetch(:model)
      end
    end

    # Configure mailer
    #
    # @param blk [Proc] the mailer configuration
    #
    # @see Hanami::Mailer.configure
    #
    # @example
    #   # config/environment.rb
    #   # ...
    #   Hanami.configure do
    #     mailer do
    #       root 'lib/bookshelf/mailers'
    #
    #       # See http://hanamirb.org/guides/mailers/delivery
    #       delivery :test
    #     end
    #
    #     # ...
    #   end
    def mailer(&blk)
      mailer_settings.push(blk) if block_given?
    end

    # @since next
    # @api private
    def mailer_settings
      settings.fetch_or_store(:mailers, [])
    end

    # @since 0.9.0
    # @api private
    def mounted
      settings.fetch_or_store(:mounted, {})
    end

    # @since 0.9.0
    # @api private
    def apps
      mounted.each_pair do |klass, app|
        yield(app) if klass.ancestors.include?(Hanami::Application)
      end
    end

    # Configure logger
    #
    # @since 1.0.0.beta1
    #
    # @param options [Hash] a set of options
    #
    # @see Hanami.logger
    # @see Hanami::Logger
    #
    # @example
    #   # config/environment.rb
    #   # ...
    #   Hanami.configure do
    #     # ...
    #     environment :development do
    #       logger level: :debug
    #     end
    #   end
    def logger(options = nil)
      if options.nil?
        settings.fetch(:logger, nil)
      else
        settings[:logger] = options
      end
    end

    # Configure settings for the current environment
    # @since 1.0.0.beta1
    #
    # @param name [Symbol] the name of the Hanami environment
    #
    # @see Hanami.env
    #
    # @example Configure Logging for Different Environments
    #   # config/environment.rb
    #   # ...
    #   Hanami.configure do
    #     # ...
    #     environment :development do
    #       logger level: :debug
    #     end
    #
    #     environment :production do
    #       logger level: :info, formatter: :json
    #     end
    #   end
    def environment(name)
      yield if ENV['HANAMI_ENV'] == name.to_s
    end

    private

    # @api private
    attr_reader :settings
  end
end
