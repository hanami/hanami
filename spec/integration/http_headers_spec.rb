RSpec.describe "HTTP headers", type: :integration do
  it "returns HTTP headers" do
    with_project do
      generate "action web home#index --url=/"

      server do
        get '/'

        expect(last_response.status).to       eq(200)
        expect(last_response.headers.keys).to eq(
          ["X-Frame-Options", "X-Content-Type-Options", "X-Xss-Protection",
           "Content-Security-Policy", "Content-Type", "Content-Length",
           "Server", "Date", "Connection"]
        )

        expect(last_response.headers["X-Frame-Options"]).to         eq("DENY")
        expect(last_response.headers["X-Content-Type-Options"]).to  eq("nosniff")
        expect(last_response.headers["X-Xss-Protection"]).to        eq("1; mode=block")
        expect(last_response.headers["Content-Security-Policy"]).to eq("form-action 'self'; frame-ancestors 'self'; base-uri 'self'; default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self' https: data:; style-src 'self' 'unsafe-inline' https:; font-src 'self'; object-src 'none'; plugin-types application/pdf; child-src 'self'; frame-src 'self'; media-src 'self'")
        expect(last_response.headers["Content-Type"]).to            eq("text/html; charset=utf-8")
        expect(Integer(last_response.headers["Content-Length"])).to be > 0
      end
    end
  end
end
