# frozen_string_literal: true

RSpec.describe "DB / auto-registration", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  it "does not auto-register files in entities/, structs/, or db/" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/db/changesets/update_posts.rb", ""
      write "app/entities/post.rb", ""
      write "app/structs/post.rb", ""

      ENV["DATABASE_URL"] = "sqlite::memory"

      require "hanami/boot"

      expect(Hanami.app.keys).not_to include("db.changesets.update_posts", "entities.post", "structs.post")
    end
  end
end
