RSpec.describe "Streaming", type: :integration do
  xit "streams the body" do
    with_project do
      generate "action web home#index --url=/"

      # Require Rack::Chunked
      unshift "apps/web/application.rb", "require 'rack/chunked'"

      # Mount middleware
      replace "apps/web/application.rb", "# middleware.use", "middleware.use ::Rack::Chunked"
      replace "apps/web/application.rb", "controller.prepare do", "controller.format text: 'text/plain'\ncontroller.prepare do"

      rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web::Controllers::Home
  class Index
    include Web::Action

    def call(params)
      self.format = :text
      self.body = Enumerator.new do |y|
        %w(one two three).each { |s| y << s }
      end
    end
  end
end
EOF

      server do
        get '/', {}, 'HTTP_VERSION' => 'HTTP/1.1'

        expect(last_response.headers).to_not have_key('Content-Length')
        expect(last_response.headers['Transfer-Encoding']).to eq("chunked")

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   eq("3\r\none\r\n3\r\ntwo\r\n5\r\nthree\r\n0\r\n\r\n")
      end
    end
  end
end
