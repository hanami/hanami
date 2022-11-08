RSpec.describe "Container / Standard providers / Rack", :app_integration do
  specify "Rack provider is loaded when rack is bundled" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/main/.keep", ""

      require "hanami/prepare"

      expect(Hanami.app["rack.monitor"]).to be_a_kind_of(Dry::Monitor::Rack::Middleware)
      expect(Main::Slice["rack.monitor"]).to be_a_kind_of(Dry::Monitor::Rack::Middleware)
    end
  end

  specify "Rack provider is not loaded when rack is not bundled" do
    allow(Hanami).to receive(:bundled?).and_call_original
    allow(Hanami).to receive(:bundled?).with("rack").and_return false

    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/main/.keep", ""

      require "hanami/prepare"

      expect(Hanami.app.key?("rack.monitor")).to be false
      expect(Main::Slice.key?("rack.monitor")).to be false
    end
  end
end
