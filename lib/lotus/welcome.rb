require 'erb'
require 'pathname'
require 'lotus/environment'
require 'lotus/utils/string'

module Lotus
  class Welcome
    def initialize(app)
      @root = Pathname.new(__dir__).join('templates').realpath
    end

    def call(env)
      @request_path = env['REQUEST_PATH'] || ''
      @body = [ERB.new(@root.join('welcome.html.erb').read).result(binding)]

      [200, {}, @body]
    end

    def application_name
      " #{ app }" if container?
    end

    private

    def container?
      Environment.new.container?
    end

    def application_class
      applications = Lotus::Application.applications.to_a
      applications.select do |app|
        @request_path.include? app.configuration.path_prefix.to_s
      end.first
    end

    def app
      Utils::String.new(application_class).namespace.downcase
    end
  end
end
