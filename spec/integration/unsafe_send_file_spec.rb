RSpec.describe "Unsafe send file", type: :integration do
  it "sends file from the public directory" do
    with_project do
      write "public/static.txt", "Static file"
      generate "action web home#index --url=/"
      rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web::Controllers::Home
  class Index
    include Web::Action

    def call(params)
      unsafe_send_file "public/static.txt"
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

  it "sends file outside of the public directory" do
    with_project do
      generate "action web home#index --url=/"
      rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web::Controllers::Home
  class Index
    include Web::Action

    def call(params)
      unsafe_send_file __FILE__
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
