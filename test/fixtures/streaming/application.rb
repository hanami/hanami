require 'rack/chunked'

module StreamingApp
  class Application < Hanami::Application
    configure do
      # Activate Streaming
      middleware.use ::Rack::Chunked
      controller.format text: 'text/plain'

      routes do
        get '/', to: 'streaming#get'
      end
    end

    load!
  end

  module Controllers::Streaming
    class Get
      include StreamingApp::Action

      def call(params)
        self.format = :text
        self.body = Enumerator.new do |y|
          %w(one two three).each { |s| y << s }
        end
      end
    end
  end
end
