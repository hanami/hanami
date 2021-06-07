# frozen_string_literal: true

require "uri"
require "concurrent/hash"
require "concurrent/array"
require "dry/inflector"
require "pathname"
require "zeitwerk"

module Hanami
  # Hanami application configuration
  #
  # @since 2.0.0
  #
  # rubocop:disable Metrics/ClassLength
  class Configuration
    require_relative "configuration/middleware"
    require_relative "configuration/router"
    require_relative "configuration/sessions"

    attr_reader :actions
    attr_reader :views

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def initialize(env:)
      @settings = Concurrent::Hash.new

      self.autoloader = Zeitwerk::Loader.new

      self.env = env
      self.environments = DEFAULT_ENVIRONMENTS.clone

      self.root = Dir.pwd
      self.slices_dir = DEFAULT_SLICES_DIR
      settings[:slices] = {}

      self.settings_path = DEFAULT_SETTINGS_PATH

      self.base_url = DEFAULT_BASE_URL

      self.logger   = DEFAULT_LOGGER.clone
      self.rack_logger_filter_params = DEFAULT_RACK_LOGGER_FILTER_PARAMS.clone
      self.sessions = DEFAULT_SESSIONS

      self.router     = Router.new(base_url)
      self.middleware = Middleware.new

      self.inflections = Dry::Inflector.new

      @actions = begin
        require_path = "hanami/action/application_configuration"
        require require_path
        Hanami::Action::ApplicationConfiguration.new
      rescue LoadError => e
        raise e unless e.path == require_path
        Object.new
      end

      @views = begin
        require_path = "hanami/view/application_configuration"
        require require_path
        Hanami::View::ApplicationConfiguration.new
      rescue LoadError => e
        raise e unless e.path == require_path
        Object.new
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def finalize
      environment_for(env).each do |blk|
        instance_eval(&blk)
      end

      # Finalize nested configuration
      #
      # TODO: would be good to just create empty configurations for actions/views
      #       instead of plain objects
      actions.finalize! if actions.respond_to?(:finalize!)
      views.finalize! if views.respond_to?(:finalize!)

      self
    end

    def environment(name, &blk)
      environment_for(name).push(blk)
    end

    def autoloader=(loader)
      settings[:autoloader] = loader || nil
    end

    def autoloader
      settings.fetch(:autoloader)
    end

    def env=(value)
      settings[:env] = value
    end

    def env
      settings.fetch(:env)
    end

    def root=(root)
      settings[:root] = Pathname(root)
    end

    def root
      settings.fetch(:root)
    end

    def slices_dir=(dir)
      settings[:slices_dir] = dir
    end

    def slices_dir
      settings.fetch(:slices_dir)
    end

    def slices_namespace=(namespace)
      settings[:slices_namespace] = namespace
    end

    def slices_namespace
      settings.fetch(:slices_namespace) { Object }
    end

    def slice(slice_name, &block)
      settings[:slices][slice_name] = block
    end

    def slices
      settings[:slices]
    end

    def settings_path=(value)
      settings[:settings_path] = value
    end

    def settings_path
      settings.fetch(:settings_path)
    end

    def settings_store=(store)
      settings[:settings_store] = store
    end

    def settings_store
      settings.fetch(:settings_store) {
        require "hanami/application/settings/dotenv_store"
        settings[:settings_store] = Application::Settings::DotenvStore.new.with_dotenv_loaded
      }
    end

    def settings_loader=(loader)
      settings[:settings_loader] = loader
    end

    def settings_loader
      settings.fetch(:settings_loader) {
        require "hanami/application/settings/loader"
        settings[:settings_loader] = Application::Settings::Loader.new
      }
    end

    def base_url=(value)
      settings[:base_url] = URI.parse(value)
    end

    def base_url
      settings.fetch(:base_url)
    end

    def logger=(options)
      settings[:logger] = options
    end

    def logger
      settings.fetch(:logger)
    end

    def rack_logger_filter_params=(params)
      settings[:rack_logger_filter_params] = params
    end

    def rack_logger_filter_params
      settings[:rack_logger_filter_params]
    end

    def router=(value)
      settings[:router] = value
    end

    def router
      settings.fetch(:router)
    end

    def sessions=(*args)
      settings[:sessions] = Sessions.new(args)
    end

    def sessions
      settings.fetch(:sessions)
    end

    def middleware
      settings.fetch(:middleware)
    end

    def inflections(&blk)
      if blk.nil?
        settings.fetch(:inflections)
      else
        settings[:inflections] = Dry::Inflector.new(&blk)
      end
    end

    alias inflector inflections

    def for_each_middleware(&blk)
      stack = middleware.stack.dup
      stack += sessions.middleware if sessions.enabled?

      stack.each(&blk)
    end

    protected

    def environment_for(name)
      settings[:environments][name]
    end

    def environments=(values)
      settings[:environments] = values
    end

    def middleware=(value)
      settings[:middleware] = value
    end

    def inflections=(value)
      settings[:inflections] = value
    end

    private

    DEFAULT_ENVIRONMENTS = Concurrent::Hash.new { |h, k| h[k] = Concurrent::Array.new }
    private_constant :DEFAULT_ENVIRONMENTS

    DEFAULT_SLICES_DIR = "slices"
    private_constant :DEFAULT_SLICES_DIR

    DEFAULT_BASE_URL = "http://0.0.0.0:2300"
    private_constant :DEFAULT_BASE_URL

    DEFAULT_LOGGER = { level: :debug }.freeze
    private_constant :DEFAULT_LOGGER

    DEFAULT_RACK_LOGGER_FILTER_PARAMS = %w[_csrf password password_confirmation].freeze
    private_constant :DEFAULT_RACK_LOGGER_FILTER_PARAMS

    DEFAULT_SETTINGS_PATH = File.join("config", "settings")
    private_constant :DEFAULT_SETTINGS_PATH

    DEFAULT_SESSIONS = Sessions.null
    private_constant :DEFAULT_SESSIONS

    attr_reader :settings
  end
  # rubocop:enable Metrics/ClassLength
end
