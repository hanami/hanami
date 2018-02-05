RSpec.describe "X-Frame-Options header", type: :integration do
  it "returns default value" do
    with_project do
      generate "action web home#index --url=/"

      server do
        get '/'

        expect(last_response.status).to                     eq(200)
        expect(last_response.headers["X-Frame-Options"]).to eq("DENY")
      end
    end
  end

  it "returns custom value" do
    with_project do
      generate "action web home#index --url=/"

      replace "apps/web/application.rb", "security.x_frame_options 'DENY'", "security.x_frame_options 'ALLOW-FROM https://example.test/'"

      server do
        get '/'

        expect(last_response.status).to                     eq(200)
        expect(last_response.headers["X-Frame-Options"]).to eq("ALLOW-FROM https://example.test/")
      end
    end
  end

  it "doesn't send header if setting is removed" do
    with_project do
      generate "action web home#index --url=/"

      replace "apps/web/application.rb", "security.x_frame_options 'DENY'", ""

      server do
        get '/'

        expect(last_response.status).to      eq(200)
        expect(last_response.headers).to_not have_key("X-Frame-Options")
      end
    end
  end
end
