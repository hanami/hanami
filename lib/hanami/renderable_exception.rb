require "rack"

module Hanami
  class RenderableException
    extend Dry::Configurable

    setting :rescue_responses, default: Hash.new(:internal_server_error).merge!(
      "Hanami::Router::NotFoundError" => :not_found
    )

    def self.status_code_for_exception(class_name)
      Rack::Utils.status_code(config.rescue_responses[class_name])
    end

    attr_reader :exception

    def initialize(exception)
      @exception = exception
    end

    def rescue_response?
      config.rescue_responses.key?(exception.class.name)
    end

    def status_code
      self.class.status_code_for_exception(exception.class.name)
    end

    private

    def config
      self.class.config
    end
  end
end
