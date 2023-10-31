# frozen_string_literal: true

RSpec.describe Hanami::Helpers::AssetsHelper, "#favicon", :app_integration do
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

  def favicon_tag(...)
    obj.instance_eval { favicon_tag(...) }
  end

  let(:root) { make_tmp_directory }
  let(:context) { TestApp::Views::Context.new }

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

      stub_assets("favicon.ico", "favicon.png")

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  it "returns an instance of SafeString" do
    actual = favicon_tag
    expect(actual).to be_instance_of(::Hanami::View::HTML::SafeString)
  end

  it "renders <link> tag" do
    actual = favicon_tag.to_s
    expect(actual).to eq(%(<link href="/assets/favicon.ico" rel="shortcut icon" type="image/x-icon">))
  end

  it "renders with HTML attributes" do
    actual = favicon_tag("favicon.png", rel: "icon", type: "image/png").to_s
    expect(actual).to eq(%(<link href="/assets/favicon.png" rel="icon" type="image/png">))
  end

  it "ignores href passed as an option" do
    actual = favicon_tag("favicon.png", href: "wrong").to_s
    expect(actual).to eq(%(<link href="/assets/favicon.png" rel="shortcut icon" type="image/x-icon">))
  end

  describe "cdn mode" do
    let(:base_url) { "https://hanami.test" }

    def before_prepare
      Hanami.app.config.assets.base_url = "https://hanami.test"
    end

    it "returns absolute url for href attribute" do
      actual = favicon_tag.to_s
      expect(actual).to eq(%(<link href="#{base_url}/assets/favicon.ico" rel="shortcut icon" type="image/x-icon">))
    end
  end
end
