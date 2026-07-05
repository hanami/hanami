# frozen_string_literal: true

RSpec.describe "Slices / Slice class loaded before the app", :app_integration do
  specify "a slice class can be defined before any app, and app? returns false" do
    # A slice class shipped inside a gem may be required before the app class is defined
    module Main
      class Slice < Hanami::Slice
      end
    end

    expect(Main::Slice.app?).to be false
  end
end
