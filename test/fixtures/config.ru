require 'hanami'

module ServerTest
  class Application < Hanami::Application
    configure do
      routes do
        route = -> (env) {
          headers = {
            'X-Hanami-Port' => ENV['HANAMI_PORT'].to_s
          }

          [200, headers, ['OK']]
        }

        get '/', to: route
      end
    end
  end
end

run ServerTest::Application.new
