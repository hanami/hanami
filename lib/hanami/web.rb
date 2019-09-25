# frozen_string_literal: true

# require_relative "../hanami"
require_relative "web/application"

module Hanami
  module Web
    def self.routes(&block)
      if block
        @routes = block
      else
        @routes
      end
    end

    def self.application
      @application ||= Application.new(Hanami.application, &routes)
    end
  end
end
