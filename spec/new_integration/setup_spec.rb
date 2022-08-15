# frozen_string_literal: true

RSpec.describe "Hanami setup", :app_integration do
  shared_examples "hanami setup" do
    it "requires the app file when found" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        setup

        expect(Hanami.app?).not_to be(nil)
      end
    end

    it "raises when the app file is not found" do
      with_tmp_directory(Dir.mktmpdir) do
        expect { setup }.to raise_error Hanami::AppLoadError, /Could not locate your Hanami app file/
      end
    end

    it "doesn't raise when the app file is not found but the app is already set" do
      require "hanami"

      module TestApp
        class App < Hanami::App
        end
      end

      expect { setup }.not_to raise_error
    end
  end

  describe "using hanami/setup require" do
    def setup
      require "hanami/setup"
    end

    it_behaves_like "hanami setup"
  end

  describe "using Hanami.setup method" do
    def setup
      require "hanami"
      Hanami.setup
    end

    it_behaves_like "hanami setup"
  end
end
