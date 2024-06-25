# frozen_string_literal: true

require "hanami/slice"

RSpec.describe "Slices / provider_source", :app_integration do
  let(:app_modules) { %i[TestApp Main] }

  it "replaces Dry::System's provider source with its own" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/slices/main.rb", <<~'RUBY'
        module Main
          class Slice < Hanami::Slice
          end
        end
      RUBY

      write "slices/main/.keep", ""

      require "hanami/prepare"

      expect { Main::Provider::Source }.to_not raise_error
      expect(Main::Provider::Source.slice).to eq Main::Slice
      expect(Main::Slice.container.config.provider_source_class).to eq provider_source
    end
  end
end
