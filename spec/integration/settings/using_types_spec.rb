# frozen_string_literal: true

require "hanami/settings"

RSpec.describe "Settings / Using types", :app_integration do
  before do
    @env = ENV.to_h
  end

  after do
    ENV.replace(@env)
  end

  specify "types from a provided types module can be used as setting constructors to coerce values" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/settings.rb", <<~RUBY
        module TestApp
          class Settings < Hanami::Settings
            Bool = Types::Params::Bool

            setting :numeric, constructor: Types::Params::Integer
            setting :flag, constructor: Bool
          end
        end
      RUBY

      ENV["NUMERIC"] = "42"
      ENV["FLAG"] = "true"

      require "hanami/prepare"

      expect(Hanami.app["settings"].numeric).to eq 42
      expect(Hanami.app["settings"].flag).to be true
    end
  end

  specify "errors raised from setting constructors are collected and re-raised in aggregate, and will prevent the app from booting" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/settings.rb", <<~RUBY
        module TestApp
          class Settings < Hanami::Settings
            setting :numeric, constructor: Types::Params::Integer
            setting :flag, constructor: Types::Params::Bool
          end
        end
      RUBY

      ENV["NUMERIC"] = "never gonna"
      ENV["FLAG"] = "give you up"

      numeric_error = "numeric: invalid value for Integer"
      flag_error = "flag: give you up cannot be coerced"

      expect {
        require "hanami/prepare"
      }.to raise_error(
        Hanami::Settings::InvalidSettingsError,
        /#{numeric_error}.+#{flag_error}|#{flag_error}.+#{numeric_error}/m
      )
    end
  end
end
