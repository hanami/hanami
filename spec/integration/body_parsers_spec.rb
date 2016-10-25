RSpec.describe "body parsers", type: :cli do
  it "parses JSON payload for non-GET requests" do
    with_project do
      generate "action web books#create --url=/books --method=POST"

      rewrite "apps/web/controllers/books/create.rb", <<-EOF
require 'json'
module Web::Controllers::Books
  class Create
    include Web::Action

    def call(params)
      self.body = JSON.dump(title: params[:book][:title])
    end
  end
end
EOF

      replace "apps/web/application.rb", "# body_parsers :json", "body_parsers :json"

      server do
        post '/books', %({"book": {"title": "CLI apps with Ruby"}}), 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json'
        expect(last_response.body).to eq(%({"title":"CLI apps with Ruby"}))
      end
    end
  end
end
