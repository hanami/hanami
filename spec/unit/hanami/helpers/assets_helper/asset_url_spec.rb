# frozen_string_literal: true

RSpec.describe Hanami::Helpers::AssetsHelper, "#asset_url", :app_integration do
  subject(:obj) {
    helpers = described_class
    Class.new {
      include helpers

      attr_reader :_context

      def initialize(context)
        @_context = context
      end
    }.new(context)
  }

  def asset_url(...)
    subject.asset_url(...)
  end

  let(:context) { TestApp::Views::Context.new }
  let(:root) { make_tmp_directory }

  before do
    with_directory(root) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
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

      write "app/assets/js/app.ts", <<~JS
        import "../css/app.css";

        console.log("Hello from index.ts");
      JS

      write "app/assets/css/app.css", <<~CSS
        .btn {
          background: #f00;
        }
      CSS

      stub_assets("app.js")

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  context "when configurated relative path only" do
    context "without manifest" do
      it "returns the relative URL to the asset" do
        expect(asset_url("app.js")).to eq("/assets/app.js")
      end

      it "returns absolute URL if the argument is an absolute URL" do
        result = asset_url("http://assets.hanamirb.org/assets/application.css")
        expect(result).to eq("http://assets.hanamirb.org/assets/application.css")
      end
    end

    context "with manifest" do
      before { compile_assets! }

      it "returns the relative URL to the asset" do
        expect(asset_url("app.js")).to match(%r{/assets/app-[A-Z0-9]{8}\.js})
      end
    end
  end

  context "when configured with base url" do
    let(:base_url) { "https://hanami.test" }

    def before_prepare
      Hanami.app.config.assets.base_url = base_url
    end

    context "without manifest" do
      it "returns the absolute URL to the asset" do
        expect(asset_url("app.js")).to eq("#{base_url}/assets/app.js")
      end
    end

    context "with manifest" do
      before { compile_assets! }

      it "returns the relative path to the asset" do
        expect(asset_url("app.js")).to match(%r{#{base_url}/assets/app-[A-Z0-9]{8}.js})
      end
    end
  end

  context "given an asset object" do
    it "returns the URL for the asset" do
      asset = Hanami::Assets::Asset.new(
        path: "/foo/bar.js",
        base_url: Hanami.app.config.assets.base_url
      )

      expect(asset_url(asset)).to eq "/foo/bar.js"
    end
  end
end
