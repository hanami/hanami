# frozen_string_literal: true

RSpec.describe "Providers / Rack", :app_integration do
  describe "#prepare" do
    let(:dir) { Dir.mktmpdir }

    it "makes rack monitoring available" do
      with_tmp_directory(dir) do
        write "config/app.rb", <<~RUBY
          require "hanami"
          require "dry/system"
          require "hanami/providers/rack"

          module TestApp
            class App < Hanami::App
              config.logger.stream = config.root.join("test.log")
            end
          end
        RUBY

        write "script/rack-test", <<~RUBY
          require_relative "../config/app"
          require "hanami/prepare"

          TestApp::App.start(:rack)

          TestApp::App["rack.monitor"].on(:error) do |event|
            puts event[:exception].message
          end

          TestApp::App[:notifications].instrument(
            :"rack.request.error", exception: StandardError.new("oops")
          )
        RUBY

        output = `cd #{dir} && bundle exec ruby script/rack-test`

        expect(output).to include("oops")
      end
    end
  end
end
