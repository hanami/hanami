RSpec.describe "Send file", type: :cli do
  it "sends file from the public directory" do
    with_project do
      write "public/static.txt", "Static file"
      generate "action web home#index --url=/"
      rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web::Controllers::Home
  class Index
    include Web::Action

    def call(params)
      send_file "static.txt"
    end
  end
end
EOF

      server do
        get '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   include("Static file")
      end
    end
  end

  it "doesn't send file outside of public directory" do
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

        expect(last_response.status).to eq(404)
      end
    end
  end
end
