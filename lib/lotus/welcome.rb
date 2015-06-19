require 'erb'
require 'pathname'
require 'lotus/environment'
require 'lotus/utils/string'

module Lotus
  class Welcome
    def initialize(app)
      @root = Pathname.new(__dir__).join('templates').realpath
      @body = [ERB.new(@root.join('welcome.html.erb').read).result(binding)]
    end

    def call(env)
      [200, {}, @body]
    end

    def application_name
      " #{ app }" if container?
    end

    private

    def container?
      Environment.new.container?
    end

    def app
      Utils::String.new(
        Application.applications.first
      ).namespace.downcase
    end
  end
end
