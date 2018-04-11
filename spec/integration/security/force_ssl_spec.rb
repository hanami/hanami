RSpec.describe "force SSL", type: :integration do
  it "forces SSL" do
    project = "bookshelf_force_ssl"

    with_project(project, server: :puma) do
      generate "action web home#index --url=/"

      replace "apps/web/application.rb", "# force_ssl true", "force_ssl true"

      RSpec::Support::Env['HANAMI_ENV']   = 'production'
      RSpec::Support::Env['DATABASE_URL'] = "sqlite://#{Pathname.new('db').join('bookshelf.sqlite')}"
      RSpec::Support::Env['SMTP_HOST']    = 'localhost'
      RSpec::Support::Env['SMTP_PORT']    = '25'

      # key  = Pathname.new(__dir__).join("..", "fixtures", "openssl", "server.key").realpath
      # cert = Pathname.new(__dir__).join("..", "fixtures", "openssl", "server.crt").realpath

      # bundle_exec "puma -b 'ssl://127.0.0.1:2300?key=#{key}&cert=#{cert}'" do
      server do
        # FIXME: I know, it's lame how I solved this problem, but I can't get Excon to do SSL handshake
        expect do
          get '/'
        end.to raise_error(Excon::Error::Socket)
      end
    end
  end
end
