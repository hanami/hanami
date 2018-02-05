RSpec.describe "X-Content-Type-Options header", type: :integration do
  it "returns default value" do
    with_project do
      generate "action web home#index --url=/"

      server do
        get '/'

        expect(last_response.status).to                            eq(200)
        expect(last_response.headers["X-Content-Type-Options"]).to eq("nosniff")
      end
    end
  end

  it "returns custom value" do
    with_project do
      generate "action web home#index --url=/"

      replace "apps/web/application.rb", "security.x_content_type_options 'nosniff'", "security.x_content_type_options 'foo'"

      server do
        get '/'

        expect(last_response.status).to                            eq(200)
        expect(last_response.headers["X-Content-Type-Options"]).to eq("foo")
      end
    end
  end

  it "doesn't send header if setting is removed" do
    with_project do
      generate "action web home#index --url=/"

      replace "apps/web/application.rb", "security.x_content_type_options 'nosniff'", ""

      server do
        get '/'

        expect(last_response.status).to      eq(200)
        expect(last_response.headers).to_not have_key("X-Content-Type-Options")
      end
    end
  end
end
