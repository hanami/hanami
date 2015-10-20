require 'rack/chunked'

module StreamingApp
  class Application < Lotus::Application
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
          y << "one"
          sleep 0.5
          y << "two"
          sleep 0.5
          y << "three"
        end
      end
    end
  end
end
