# frozen_string_literal: true

RSpec.describe "Slices / Slice class loaded before the app", :app_integration do
  specify "a slice class defined before any app is its own app until an app is defined" do
    # A slice class shipped inside a gem may be required before the app class is defined
    module Main
      class Slice < Hanami::Slice
      end
    end

    # With no app defined, the outermost slice acts as the app
    expect(Main::Slice.app).to be Main::Slice
    expect(Main::Slice.app?).to be true

    module TestApp
      class App < Hanami::App
      end
    end

    expect(Main::Slice.app).to be TestApp::App
    expect(Main::Slice.app?).to be false
  end
end
