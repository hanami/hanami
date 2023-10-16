# frozen_string_literal: true

RSpec.describe Hanami::Helpers::AssetsHelper, "#video", :app_integration do
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

  def video_tag(...)
    subject.video_tag(...)
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

      stub_assets("movie.mp4", "movie.en.vtt")

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  it "returns an instance of HtmlBuilder" do
    actual = video_tag("movie.mp4")
    expect(actual).to be_instance_of(::Hanami::View::HTML::SafeString)
  end

  it "renders <video> tag" do
    actual = video_tag("movie.mp4").to_s
    expect(actual).to eq(%(<video src="/assets/movie.mp4"></video>))
  end

  it "is aliased as #video_tag" do
    expect(video_tag("movie.mp4")).to eq(subject.video_tag("movie.mp4"))
  end

  it "renders with html attributes" do
    actual = video_tag("movie.mp4", autoplay: true, controls: true).to_s
    expect(actual).to eq(%(<video autoplay="autoplay" controls="controls" src="/assets/movie.mp4"></video>))
  end

  it "renders with fallback content" do
    actual = video_tag("movie.mp4") do
      "Your browser does not support the video tag"
    end.to_s

    expect(actual).to eq(%(<video src="/assets/movie.mp4">Your browser does not support the video tag</video>))
  end

  it "renders with tracks" do
    actual = video_tag("movie.mp4") do
      tag.track kind: "captions", src: subject.asset_url("movie.en.vtt"), srclang: "en", label: "English"
    end.to_s

    expect(actual).to eq(%(<video src="/assets/movie.mp4"><track kind="captions" src="/assets/movie.en.vtt" srclang="en" label="English"></video>))
  end

  xit "renders with sources" do
    actual = subject.video do
      tag.text "Your browser does not support the video tag"
      tag.source src: subject.asset_url("movie.mp4"), type: "video/mp4"
      tag.source src: subject.asset_url("movie.ogg"), type: "video/ogg"
    end.to_s

    expect(actual).to eq(%(<video>Your browser does not support the video tag<source src="/assets/movie.mp4" type="video/mp4"><source src="/assets/movie.ogg" type="video/ogg"></video>))
  end

  it "raises an exception when no arguments" do
    expect do
      video_tag
    end.to raise_error(
      ArgumentError,
      "You should provide a source via `src` option or with a `source` HTML tag"
    )
  end

  it "raises an exception when no src and no block" do
    expect do
      video_tag(content: true)
    end.to raise_error(
      ArgumentError,
      "You should provide a source via `src` option or with a `source` HTML tag"
    )
  end

  describe "cdn mode" do
    let(:base_url) { "https://hanami.test" }

    def before_prepare
      Hanami.app.config.assets.base_url = "https://hanami.test"
    end

    it "returns absolute url for src attribute" do
      actual = video_tag("movie.mp4").to_s
      expect(actual).to eq(%(<video src="#{base_url}/assets/movie.mp4"></video>))
    end
  end

  private

  def tag(...)
    subject.__send__(:tag, ...)
  end
end
