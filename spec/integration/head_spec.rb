RSpec.describe "HTTP HEAD", type: :integration do
  it "returns empty body for HEAD requests" do
    with_project do
      generate "action web home#index --url=/"

      server do
        head '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   eq("")
      end
    end
  end

  it "returns empty body for HEAD requests when body is set by the action" do
    with_project do
      generate "action web home#index --url=/"
      rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web::Controllers::Home
  class Index
    include Web::Action

    def call(params)
      self.body = "Hello"
    end
  end
end
EOF

      server do
        head '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   eq("")
      end
    end
  end

  it "returns empty body for HEAD requests when body is set by the view" do
    with_project do
      generate "action web home#index --url=/"
      rewrite "apps/web/views/home/index.rb", <<-EOF
module Web::Views::Home
  class Index
    include Web::View

    def render
      "World"
    end
  end
end
EOF

      server do
        head '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   eq("")
      end
    end
  end

  it "returns empty body for HEAD requests with send file" do
    with_project do
      write "public/static.txt", "Plain text file"
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
        head '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   eq("")
      end
    end
  end
end
