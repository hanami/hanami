# frozen_string_literal: true

RSpec.describe "Hanami setup", :app_integration do
  it "requires the app file when found" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
       require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      require "hanami/setup"

      expect(Hanami.app?).not_to be(nil)
    end
  end

  it "raises when the app file is not found" do
    with_tmp_directory(Dir.mktmpdir) do
      expect { require "hanami/setup" }.to raise_error /Hanami hasn't been able to locate your application file/
    end
  end

  it "doesn't raise when the app file is not found but the app is already set" do
    require "hanami"

    module TestApp
      class App < Hanami::App
      end
    end

    expect { require "hanami/setup" }.not_to raise_error
  end
end
