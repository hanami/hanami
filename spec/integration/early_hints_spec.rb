# frozen_string_literal: true

RSpec.describe "Early Hints", type: :integration do
  it "pushes assets" do
    skip "curl not installed" if which("curl").nil?

    with_project("bookshelf", server: :puma) do
      generate "action web home#index --url=/"

      write "apps/web/assets/javascripts/app.css", <<~EOF
        body { margin: 0; }
      EOF

      inject_line_after "apps/web/templates/app.html.erb", /favicon/, %(<%= stylesheet "app" %>)
      inject_line_after "config/environment.rb", /mount/, "early_hints true"

      write "config/puma.rb", <<~EOF
        early_hints true
      EOF

      port = RSpec::Support::RandomPort.call
      server(port: port) do
        sleep 2

        # The Ruby HTTP client that we use for testing (excon), fails to connect to the server.
        # It's very likely that it assumes that for each request, the server will return only one response.
        # But in case of Early Hints (103) the returned response are multiple: `n` Early Hints (103) + OK (200).
        #
        # For this reason we fall back to cURL for this test.
        system_exec("curl -i -v http://localhost:#{port}/")
        expect(out).to include("Link: </assets/app.css>; rel=preload; as=style")
      end
    end
  end
end
