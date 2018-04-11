RSpec.describe "Content-Security-Policy header", type: :integration do
  it "returns default value" do
    with_project do
      generate "action web home#index --url=/"

      server do
        get '/'

        expect(last_response.status).to                             eq(200)
        expect(last_response.headers["Content-Security-Policy"]).to eq("form-action 'self'; frame-ancestors 'self'; base-uri 'self'; default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self' https: data:; style-src 'self' 'unsafe-inline' https:; font-src 'self'; object-src 'none'; plugin-types application/pdf; child-src 'self'; frame-src 'self'; media-src 'self'")
      end
    end
  end

  it "returns custom value" do
    with_project do
      generate "action web home#index --url=/"

      replace "apps/web/application.rb", "script-src 'self';", "script-src 'self' https://code.jquery.com;"

      server do
        get '/'

        expect(last_response.status).to                             eq(200)
        expect(last_response.headers["Content-Security-Policy"]).to eq("form-action 'self'; frame-ancestors 'self'; base-uri 'self'; default-src 'none'; script-src 'self' https://code.jquery.com; connect-src 'self'; img-src 'self' https: data:; style-src 'self' 'unsafe-inline' https:; font-src 'self'; object-src 'none'; plugin-types application/pdf; child-src 'self'; frame-src 'self'; media-src 'self'")
      end
    end
  end

  it "doesn't send header if setting is removed" do
    with_project do
      generate "action web home#index --url=/"

      replace "apps/web/application.rb", "security.content_security_policy %{", "%{"

      server do
        get '/'

        expect(last_response.status).to      eq(200)
        expect(last_response.headers).to_not have_key("Content-Security-Policy")
      end
    end
  end
end
