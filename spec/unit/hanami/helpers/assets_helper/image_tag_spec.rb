# frozen_string_literal: true

RSpec.describe Hanami::Helpers::AssetsHelper, "#image", :app_integration do
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

  def image_tag(...)
    subject.image_tag(...)
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

      stub_assets("application.jpg")

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  it "returns an instance of HtmlBuilder" do
    actual = image_tag("application.jpg")
    expect(actual).to be_instance_of(::Hanami::View::HTML::SafeString)
  end

  it "renders an <img> tag" do
    actual = image_tag("application.jpg").to_s
    expect(actual).to eq(%(<img src="/assets/application.jpg" alt="Application">))
  end

  it "custom alt" do
    actual = image_tag("application.jpg", alt: "My Alt").to_s
    expect(actual).to eq(%(<img src="/assets/application.jpg" alt="My Alt">))
  end

  it "custom data attribute" do
    actual = image_tag("application.jpg", "data-user-id" => 5).to_s
    expect(actual).to eq(%(<img src="/assets/application.jpg" alt="Application" data-user-id="5">))
  end

  it "ignores src passed as an option" do
    actual = image_tag("application.jpg", src: "wrong").to_s
    expect(actual).to eq(%(<img src="/assets/application.jpg" alt="Application">))
  end

  describe "cdn mode" do
    let(:base_url) { "https://hanami.test" }

    def before_prepare
      Hanami.app.config.assets.base_url = "https://hanami.test"
    end

    it "returns absolute url for src attribute" do
      actual = image_tag("application.jpg").to_s
      expect(actual).to eq(%(<img src="#{base_url}/assets/application.jpg" alt="Application">))
    end
  end
end
