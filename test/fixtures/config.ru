require 'lotus'

module ServerTest
  class Application < Lotus::Application
    configure do
      routes do
        route = -> (env) {
          headers = {
            'X-Lotus-Port' => ENV['LOTUS_PORT'].to_s
          }

          [200, headers, ['OK']]
        }

        get '/', to: route
      end
    end
  end
end

run ServerTest::Application.new
