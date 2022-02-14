# frozen_string_literal: true

RSpec.describe "Slices", :application_integration do
  it "Loading a slice uses a defined slice class" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "slices/main/slice.rb", <<~RUBY
        module Main
          class Slice < Hanami::Slice
          end
        end
      RUBY

      write "slices/main/lib/foo.rb", <<~RUBY
        module Main
          class Foo; end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.application.slices[:main]).to be Main::Slice
    end
  end

  it "Loading a slice generates a slice class if none is defined" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "slices/main/lib/foo.rb", <<~RUBY
        module Main
          class Foo; end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.application.slices[:main]).to be Main::Slice
    end
  end
end
