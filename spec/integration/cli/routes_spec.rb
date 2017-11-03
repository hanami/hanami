RSpec.describe "hanami routes", type: :cli do
  it "prints application routes" do
    with_project do
      generate "app admin"

      write "lib/ping.rb", <<-EOF
      class Ping
        def call(env)
          [200, {}, ["PONG"]]
        end
      end
EOF

      unshift "config/environment.rb", "require_relative '../lib/ping'"
      replace "config/environment.rb", "Hanami.configure do", "Hanami.configure do\nmount Ping, at: '/ping'"

      generate "action web home#index --url=/"
      generate "action web books#create --url=/books --method=POST"

      generate "action admin home#index --url=/"

      hanami "routes"

      expect(out).to eq "Name Method     Path                           Action                        \n\n                                /ping                          Ping                          \n\n                Name Method     Path                           Action                        \n\n                     GET, HEAD  /admin                         Admin::Controllers::Home::Index\n\n                Name Method     Path                           Action                        \n\n                     POST       /books                         Web::Controllers::Books::Create\n                     GET, HEAD  /                              Web::Controllers::Home::Index"
    end
  end
end
