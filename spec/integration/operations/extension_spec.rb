# frozen_string_literal: true

require "dry/operation"

RSpec.describe "Operation / Extensions", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after { ENV.replace(@env) }

  specify "Transaction interface is made available automatically" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
      RUBY

      write "app/operation.rb", <<~RUBY
        module TestApp
          class Operation < Dry::Operation
          end
        end
      RUBY

      write "slices/main/operation.rb", <<~RUBY
        module Main
          class Operation < Dry::Operation
          end
        end
      RUBY

      write "db/.keep", ""
      write "app/relations/.keep", ""

      write "slices/main/db/.keep", ""
      write "slices/main/relations/.keep", ""

      ENV["DATABASE_URL"] = "sqlite::memory"
      ENV["MAIN__DATABASE_URL"] = "sqlite::memory"

      require "hanami/prepare"

      app = TestApp::Operation.new
      main = Main::Operation.new

      expect(app).to respond_to(:transaction)

      expect(app.rom.object_id).to eq TestApp::App["db.rom"].object_id
      expect(app.rom.object_id).to_not eq Main::Slice["db.rom"].object_id
    end
  end
end
