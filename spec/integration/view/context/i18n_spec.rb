# frozen_string_literal: true

require "hanami"

RSpec.describe "App view / Context / I18n", :app_integration do
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

  describe "#i18n" do
    context "i18n gem bundled" do
      it "is the app's i18n backend" do
        expect(context.i18n).to be TestApp::App["i18n"]
      end
    end

    context "i18n gem not bundled" do
      def before_prepare
        # This must be here instead of an ordinary before hook because the Hanami.bundled? check for
        # i18n is done as part of requiring "hanami/prepare" above.
        allow(Hanami).to receive(:bundled?).and_call_original
        allow(Hanami).to receive(:bundled?).with("i18n").and_return(false)
      end

      it "raises error" do
        expect { context.i18n }.to raise_error(Hanami::ComponentLoadError, /i18n gem is required/)
      end
    end

    context "injected i18n" do
      subject(:context) {
        context_class.new(i18n: i18n)
      }

      let(:i18n) { double(:i18n) }

      it "is the injected i18n" do
        expect(context.i18n).to be i18n
      end
    end
  end
end
