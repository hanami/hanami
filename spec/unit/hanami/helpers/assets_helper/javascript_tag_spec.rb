# frozen_string_literal: true

RSpec.describe Hanami::Helpers::AssetsHelper, "#javascript", :app_integration do
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

  def javascript_tag(...)
    subject.javascript_tag(...)
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

      stub_assets("feature-a.js")

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  it "returns an instance of SafeString" do
    actual = javascript_tag("feature-a")
    expect(actual).to be_instance_of(::Hanami::View::HTML::SafeString)
  end

  it "is aliased as #javascript_tag" do
    expect(subject.javascript_tag("feature-a")).to eq javascript_tag("feature-a")
  end

  it "renders <script> tag" do
    actual = javascript_tag("feature-a")
    expect(actual).to eq(%(<script src="/assets/feature-a.js" type="text/javascript"></script>))
  end

  xit "renders <script> tag without appending ext after query string" do
    actual = javascript_tag("feature-x?callback=init")
    expect(actual).to eq(%(<script src="/assets/feature-x?callback=init" type="text/javascript"></script>))
  end

  it "renders <script> tag with a defer attribute" do
    actual = javascript_tag("feature-a", defer: true)
    expect(actual).to eq(%(<script src="/assets/feature-a.js" type="text/javascript" defer="defer"></script>))
  end

  it "renders <script> tag with an integrity attribute" do
    actual = javascript_tag("feature-a", integrity: "sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC")
    expect(actual).to eq(%(<script src="/assets/feature-a.js" type="text/javascript" integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC" crossorigin="anonymous"></script>))
  end

  it "renders <script> tag with a crossorigin attribute" do
    actual = javascript_tag("feature-a", integrity: "sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC", crossorigin: "use-credentials")
    expect(actual).to eq(%(<script src="/assets/feature-a.js" type="text/javascript" integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC" crossorigin="use-credentials"></script>))
  end

  it "ignores src passed as an option" do
    actual = javascript_tag("feature-a", src: "wrong")
    expect(actual).to eq(%(<script src="/assets/feature-a.js" type="text/javascript"></script>))
  end

  describe "async option" do
    it "renders <script> tag with an async=true if async option is true" do
      actual = javascript_tag("feature-a", async: true)
      expect(actual).to eq(%(<script src="/assets/feature-a.js" type="text/javascript" async="async"></script>))
    end

    it "renders <script> tag without an async=true if async option is false" do
      actual = javascript_tag("feature-a", async: false)
      expect(actual).to eq(%(<script src="/assets/feature-a.js" type="text/javascript"></script>))
    end
  end

  describe "subresource_integrity mode" do
    def before_prepare
      Hanami.app.config.assets.subresource_integrity = [:sha384]
    end

    before { compile_assets! }

    it "includes subresource_integrity and crossorigin attributes" do
      actual = javascript_tag("app")
      expect(actual).to match(%r{<script src="/assets/app-[A-Z0-9]{8}.js" type="text/javascript" integrity="sha384-[A-Za-z0-9+/]{64}" crossorigin="anonymous"></script>})
    end
  end

  describe "cdn mode" do
    let(:base_url) { "https://hanami.test" }

    def before_prepare
      Hanami.app.config.assets.base_url = "https://hanami.test"
    end

    it "returns absolute url for src attribute" do
      actual = javascript_tag("feature-a")
      expect(actual).to eq(%(<script src="#{base_url}/assets/feature-a.js" type="text/javascript"></script>))
    end
  end
end
