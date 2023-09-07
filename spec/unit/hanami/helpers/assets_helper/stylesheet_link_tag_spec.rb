# frozen_string_literal: true

RSpec.describe Hanami::Helpers::AssetsHelper, "#stylesheet_link_tag", :app_integration do
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

  def stylesheet_link_tag(...)
    subject.stylesheet_link_tag(...)
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

      write "app/assets/javascripts/app.ts", <<~JS
        import "../stylesheets/app.css";

        console.log("Hello from index.ts");
      JS

      write "app/assets/stylesheets/app.css", <<~CSS
        .btn {
          background: #f00;
        }
      CSS

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  it "returns an instance of SafeString" do
    actual = stylesheet_link_tag("main")
    expect(actual).to be_instance_of(::Hanami::View::HTML::SafeString)
  end

  it "renders <link> tag" do
    actual = stylesheet_link_tag("main")
    expect(actual).to eq(%(<link href="/assets/main.css" type="text/css" rel="stylesheet">))
  end

  it "renders <link> tag without appending ext after query string" do
    actual = stylesheet_link_tag("fonts?font=Helvetica")
    expect(actual).to eq(%(<link href="/assets/fonts?font=Helvetica" type="text/css" rel="stylesheet">))
  end

  it "renders <link> tag with an integrity attribute" do
    actual = stylesheet_link_tag("main", integrity: "sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC")
    expect(actual).to eq(%(<link href="/assets/main.css" type="text/css" rel="stylesheet" integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC" crossorigin="anonymous">))
  end

  it "renders <link> tag with a crossorigin attribute" do
    actual = stylesheet_link_tag("main", integrity: "sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC", crossorigin: "use-credentials")
    expect(actual).to eq(%(<link href="/assets/main.css" type="text/css" rel="stylesheet" integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC" crossorigin="use-credentials">))
  end

  it "ignores href passed as an option" do
    actual = stylesheet_link_tag("main", href: "wrong")
    expect(actual).to eq(%(<link href="/assets/main.css" type="text/css" rel="stylesheet">))
  end

  describe "subresource_integrity mode" do
    def before_prepare
      Hanami.app.config.assets.subresource_integrity = [:sha384]
    end

    before { precompile_assets! }

    it "includes subresource_integrity and crossorigin attributes" do
      actual = stylesheet_link_tag("app")
      expect(actual).to eq(%(<link href="/assets/app-BDJPH3XR.css" type="text/css" rel="stylesheet" integrity="sha384-AT14m59DGIJJp8AsoZmdt25b0+KdyQYMC7ARf9DgmNtmtGddGr/2TaGUgBCR5x+v" crossorigin="anonymous">))
    end
  end

  describe "cdn mode" do
    let(:base_url) { "https://hanami.test" }

    def before_prepare
      Hanami.app.config.assets.base_url = base_url
    end

    it "returns absolute url for href attribute" do
      actual = stylesheet_link_tag("app")
      expect(actual).to eq(%(<link href="#{base_url}/assets/app.css" type="text/css" rel="stylesheet">))
    end
  end
end
