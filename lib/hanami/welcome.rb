require 'erb'
require 'pathname'
require 'hanami/environment'
require 'hanami/utils/string'

module Hanami
  # @api private
  class Welcome
    # @api private
    def initialize(_app)
      @root = Pathname.new(__dir__).join('templates').realpath
    end

    # @api private
    def call(env)
      @request_path = env['REQUEST_PATH'] || ''
      @body = [ERB.new(@root.join('welcome.html.erb').read).result(binding)]

      [200, {}, @body]
    end

    # @api private
    def application_name
      application_class.app_name
    end

    private

    # @api private
    def application_class
      Hanami.configuration.apps do |app|
        return app if @request_path.include?(app.path_prefix)
      end
    end
  end
end
