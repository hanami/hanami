RSpec.describe "Send file", type: :cli do
  it "sends file" do
    with_project do
      generate "action web home#index --url=/"
      rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web::Controllers::Home
  class Index
    include Web::Action

    def call(params)
      send_file __FILE__
    end
  end
end
EOF

      server do
        get '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   include("Web::Controllers::Home")
      end
    end
  end
end
