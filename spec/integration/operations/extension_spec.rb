# frozen_string_literal: true

require "dry/operation"

RSpec.describe "Operation / Extensions", :app_integration do
  specify "Transaction interface is made available automatically" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      require "./config/app"

      expect(Dry::Operation.new).to respond_to(:transaction)
    end
  end
end
