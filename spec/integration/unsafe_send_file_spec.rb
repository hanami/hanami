RSpec.describe "Unsafe send file", type: :cli do
  it "sends file from the public directory" do
    with_project do
      write "public/static.txt", "Static file"
      generate "action web home#index --url=/"
      rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web
  module Controllers
    module Home
      class Index < Hanami::Action
        def call(*, res)
          res.unsafe_send_file "public/static.txt"
        end
      end
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
module Web
  module Controllers
    module Home
      class Index < Hanami::Action
        def call(*, res)
          res.unsafe_send_file __FILE__
        end
      end
    end
  end
end
EOF

      server do
        get '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   include("class Index < Hanami::Action")
      end
    end
  end
end
