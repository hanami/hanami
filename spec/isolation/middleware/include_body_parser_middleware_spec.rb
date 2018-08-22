RSpec.describe Hanami::Middleware, type: :integration do
  describe "#load!" do
    it "include the BodyParser Middleware when using the body_parses configuration" do
      with_project do
        generate "action web home#index"

        replace "apps/web/application.rb", "configure do", <<-END
configure do
  body_parsers :json
END

        require Pathname.new(Dir.pwd).join("config", "environment")
        Hanami::Components.resolve('all')

        middleware = Web::Application.new.__send__(:middleware)

        expect(middleware.__send__(:stack)).to include([Hanami::Middleware::BodyParser, [[:json]], nil])
      end
    end
  end
end
