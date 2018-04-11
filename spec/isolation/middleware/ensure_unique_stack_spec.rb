RSpec.describe Hanami::Middleware, type: :integration do
  describe "#load!" do
    it "loads the middleware stack without duplicates" do
      with_project do
        generate "action web home#index"
        replace "apps/web/application.rb", "Application < Hanami::Application", <<-END
class RackApp
  def initialize(app, options = {}, &blk)
    @app     = app
    @options = options
    @blk     = blk
  end

  def call(env)
    @app.call(env)
  end
end

class Application < Hanami::Application
END

        replace "apps/web/application.rb", "configure do", <<-END
configure do
  block1 = ->() {}
  block2 = ->() {}
  block3 = ->() {}

  middleware.use Web::RackApp, foo: :bar
  middleware.use Web::RackApp, foo: :bar # this is a duplicate and it shouldn't be included
  middleware.use Web::RackApp, baz: :bat
  middleware.use Web::RackApp, &block1
  middleware.use Web::RackApp, &block1   # this is a duplicate and it shouldn't be included
  middleware.use Web::RackApp, &block2

  middleware.prepend Web::RackApp, foo: :bar # this is a duplicate and it shouldn't be included
  middleware.prepend Web::RackApp, cap: :tain
  middleware.prepend Web::RackApp, &block1   # this is a duplicate and it shouldn't be included
  middleware.prepend Web::RackApp, &block2   # this is a duplicate and it shouldn't be included
  middleware.prepend Web::RackApp, &block3
END

        require Pathname.new(Dir.pwd).join("config", "environment")
        Hanami::Components.resolve('all')

        middleware = Web::Application.new.__send__(:middleware)

        # We tried to mount Web::RackApp 11 times.
        #
        # We have 5 duplicates marked inline.
        #
        # That leads us to 6 (11 - 5) mounted middleware.
        expect(middleware.__send__(:stack).count).to be(6)
      end
    end
  end
end
