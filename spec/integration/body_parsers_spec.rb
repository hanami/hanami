RSpec.describe "body parsers", type: :integration do
  it "parses JSON payload for non-GET requests" do
    with_project do
      generate_action
      enable_json_body_parser

      server do
        post '/books', %({"book": {"title": "CLI apps with Ruby"}}), 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json'
        expect(last_response.body).to eq(%({"book":{"title":"CLI apps with Ruby"}}))
      end
    end
  end

  it "doesn't eval untrusted JSON" do
    with_project do
      generate_action
      enable_json_body_parser

      server do
        post '/books', %({"json_class": "Foo"}), 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json'
        expect(last_response.body).to eq(%({"json_class":"Foo"}))
      end
    end
  end

  private

  def generate_action
    generate "action web books#create --url=/books --method=POST"

    rewrite "apps/web/controllers/books/create.rb", <<-EOF
require 'hanami/utils/json'
module Web::Controllers::Books
  class Create
    include Web::Action

    def call(params)
      self.body = Hanami::Utils::Json.generate(params.to_hash)
    end
  end
end
EOF
  end

  def enable_json_body_parser
    replace "apps/web/application.rb", "# body_parsers :json", "body_parsers :json"
  end
end
