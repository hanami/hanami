# frozen_string_literal: true

require "hanami"

RSpec.describe "App view / Context / Assets", :app_integration do
  subject(:context) { context_class.new }
  let(:context_class) { TestApp::Views::Context }

  before do
    with_directory(make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
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

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  context "assets present and hanami-assets bundled" do
    def before_prepare
      write "app/assets/.keep", ""
    end

    it "is the app assets by default" do
      expect(context.assets).to be TestApp::App[:assets]
    end
  end

  context "assets not present" do
    it "raises error" do
      expect { context.assets }.to raise_error(Hanami::ComponentLoadError, /assets directory\?/)
    end
  end

  context "hanami-assets not bundled" do
    def before_prepare
      # These must be here instead of an ordinary before hook because the Hanami.bundled? check for
      # assets is done as part of requiring "hanami/prepare" above.
      allow(Hanami).to receive(:bundled?).and_call_original
      allow(Hanami).to receive(:bundled?).with("hanami-assets").and_return(false)

      write "app/assets/.keep", ""
    end

    it "raises error" do
      expect { context.assets }.to raise_error(Hanami::ComponentLoadError, /hanami-assets gem/)
    end
  end

  context "injected assets" do
    subject(:context) {
      context_class.new(assets: assets)
    }

    let(:assets) { double(:assets) }

    it "is the injected assets" do
      expect(context.assets).to be assets
    end
  end
end
