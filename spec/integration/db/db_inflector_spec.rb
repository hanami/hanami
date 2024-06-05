# frozen_string_literal: true

require "dry/system"

RSpec.describe "ROM::Inflector", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  around :each do |example|
    inflector = ROM::Inflector
    ROM.instance_eval {
      remove_const :Inflector
      const_set :Inflector, Dry::Inflector.new
    }
    example.run
  ensure
    ROM.instance_eval {
      remove_const :Inflector
      const_set :Inflector, inflector
    }
  end

  it "replaces ROM::Inflector with the Hanami inflector" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/relations/posts.rb", <<~RUBY
        module TestApp
          module Relations
            class Posts < Hanami::DB::Relation
              schema :posts, infer: true
            end
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite::memory"

      require "hanami/prepare"

      expect { Hanami.app.prepare :db }.to change { ROM::Inflector == Hanami.app["inflector"] }.from(false).to(true)
    end
  end
end
