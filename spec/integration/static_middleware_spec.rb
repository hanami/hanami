RSpec.describe "Static middleware", type: :integration do
  it "serves a public file" do
    with_project do
      write "public/static.txt", "Static file"

      RSpec::Support::Env['HANAMI_ENV']          = 'production'
      RSpec::Support::Env['DATABASE_URL']        = "sqlite://#{Pathname.new('db').join('bookshelf.sqlite')}"
      RSpec::Support::Env['SERVE_STATIC_ASSETS'] = "true"
      RSpec::Support::Env['SMTP_HOST']           = 'localhost'
      RSpec::Support::Env['SMTP_PORT']           = '25'

      server do
        visit '/static.txt'

        expect(page.body).to include("Static file")
      end
    end
  end
end
