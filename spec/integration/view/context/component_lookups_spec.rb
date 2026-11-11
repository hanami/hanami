# frozen_string_literal: true

require "hanami"

RSpec.describe "App view / Context / Component lookups", :app_integration do
  let(:context_class) { TestApp::Views::Context }

  def prepare_app
    with_directory(make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            root to: ->(*) { [200, {}, ["OK"]] }
          end
        end
      RUBY

      write "app/views/context.rb", <<~RUBY
        # auto_register: false

        require "hanami/view/context"

        module TestApp
          module Views
            class Context < Hanami::View::Context
            end
          end
        end
      RUBY

      write "app/assets/.keep", ""

      require "hanami/prepare"
    end
  end

  context "in a booted app" do
    before do
      prepare_app
      Hanami.app.boot
    end

    it "provides the app's components to every context" do
      first = context_class.new
      second = context_class.new

      expect(first.routes).to be_a Hanami::Slice::RoutesHelper
      expect(first.routes.path(:root)).to eq "/"
      expect(first.assets).to be TestApp::App["assets"]

      expect(second.routes).to be first.routes
      expect(second.assets).to be first.assets
    end

    it "looks each component up once" do
      context_class.new

      expect(Hanami.app).not_to receive(:key?)
      expect(Hanami.app).not_to receive(:[])

      context = context_class.new

      expect(context.routes).not_to be_nil
      expect(context.assets).not_to be_nil
    end

    it "still accepts components given to the context" do
      context_class.new
      routes = double(:routes)

      expect(context_class.new(routes: routes).routes).to be routes
    end
  end

  context "in an app that is not booted" do
    before { prepare_app }

    it "looks each component up for every context" do
      context_class.new

      expect(Hanami.app).to receive(:key?).at_least(:once).and_call_original

      expect(context_class.new.routes.path(:root)).to eq "/"
    end
  end

  context "in the test env" do
    before do
      @orig_env = ENV.to_h
      ENV["HANAMI_ENV"] = "test"

      prepare_app
      Hanami.app.boot
    end

    after do
      ENV.replace(@orig_env)
    end

    it "looks each component up for every context, so they can be stubbed" do
      context_class.new

      expect(Hanami.app).to receive(:key?).at_least(:once).and_call_original

      expect(context_class.new.routes.path(:root)).to eq "/"
    end
  end
end
