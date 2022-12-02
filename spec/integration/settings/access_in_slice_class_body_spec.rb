# frozen_string_literal: true

RSpec.describe "Settings / Access within slice class bodies", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  context "app class" do
    it "provides access to the settings inside the class body" do
      with_directory(make_tmp_directory) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              @some_flag = settings.some_flag
            end
          end
        RUBY

        write ".env", <<~'TEXT'
          SOME_FLAG=true
        TEXT

        write "config/settings.rb", <<~'RUBY'
          module TestApp
            class Settings < Hanami::Settings
              setting :some_flag
            end
          end
        RUBY

        require "hanami/setup"

        expect(Hanami.app.instance_variable_get(:@some_flag)).to eq "true"
      end
    end
  end

  context "slice class" do
    it "provides access to the settings inside the class body" do
      with_directory(make_tmp_directory) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "config/slices/main.rb", <<~'RUBY'
          module Main
            class Slice < Hanami::Slice
              @some_flag = settings.some_flag
            end
          end
        RUBY

        write ".env", <<~'TEXT'
          SOME_FLAG=true
        TEXT

        write "slices/main/config/settings.rb", <<~'RUBY'
          module Main
            class Settings < Hanami::Settings
              setting :some_flag
            end
          end
        RUBY

        require "hanami/prepare"

        expect(Main::Slice.instance_variable_get(:@some_flag)).to eq "true"
      end
    end
  end
end
