RSpec.describe "X-XSS-Protection header", type: :integration do
  it "returns default value" do
    with_project do
      generate "action web home#index --url=/"

      server do
        get '/'

        expect(last_response.status).to                      eq(200)
        expect(last_response.headers["X-XSS-Protection"]).to eq("1; mode=block")
      end
    end
  end

  it "returns custom value" do
    with_project do
      generate "action web home#index --url=/"

      replace "apps/web/application.rb", "security.x_xss_protection '1; mode=block'", "security.x_xss_protection '0'"

      server do
        get '/'

        expect(last_response.status).to                      eq(200)
        expect(last_response.headers["X-XSS-Protection"]).to eq("0")
      end
    end
  end

  it "doesn't send header if setting is removed" do
    with_project do
      generate "action web home#index --url=/"

      replace "apps/web/application.rb", "security.x_xss_protection '1; mode=block'", ""

      server do
        get '/'

        expect(last_response.status).to      eq(200)
        expect(last_response.headers).to_not have_key("X-XSS-Protection")
      end
    end
  end
end
