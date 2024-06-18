# frozen_string_literal: true

RSpec.describe "DB / Provider / Config", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  it "is a Hanami::Providers::DB::Config" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/db/.keep", ""

      ENV["DATABASE_URL"] = "sqlite::memory"

      require "hanami/prepare"

      provider = Hanami.app.container.providers[:db]
      expect(provider.source.config).to be_an_instance_of Hanami::Providers::DB::Config
    end
  end
end
