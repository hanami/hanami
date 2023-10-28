# frozen_string_literal: true

RSpec.describe "Slices", :app_integration do
  specify "Loading a slice from a slice class in the app's config dir" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/slices/main.rb", <<~RUBY
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

      expect(Hanami.app.slices[:main]).to be Main::Slice
    end
  end

  specify "Loading a slice from a slice class in the app's config dir, even when no slice dir exists" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/slices/main.rb", <<~RUBY
        module Main
          class Slice < Hanami::Slice
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main]).to be Main::Slice
    end
  end

  specify "Loading a nested slice from a slice class in its parent's config dir" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/main/config/slices/nested.rb", <<~RUBY
        module Main
          module Nested
            class Slice < Hanami::Slice
            end
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main].slices[:nested]).to be Main::Nested::Slice
    end
  end

  specify "Loading a slice from a slice class in its own config dir" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/main/config/slice.rb", <<~RUBY
        module Main
          class Slice < Hanami::Slice
            def self.loaded_from = "own config dir"
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main]).to be Main::Slice
      expect(Hanami.app.slices[:main].loaded_from).to eq "own config dir"
    end
  end

  specify "Loading a slice from a slice class in the app's config dir, in preference to a slice class in its own config dir" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/slices/main.rb", <<~RUBY
        require "hanami"

        module Main
          class Slice < Hanami::Slice
            def self.loaded_from = "app config dir"
          end
        end
      RUBY

      write "slices/main/config/slice.rb", <<~RUBY
        raise "This should not be loaded"
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main]).to be Main::Slice
      expect(Hanami.app.slices[:main].loaded_from).to eq "app config dir"
    end
  end

  specify "Loading a nested slice from a slice class in its own config dir" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/main/slices/nested/config/slice.rb", <<~RUBY
        module Main
          module Nested
            class Slice < Hanami::Slice
              def self.loaded_from = "own config dir"
            end
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main]).to be Main::Slice
      expect(Hanami.app.slices[:main].slices[:nested].loaded_from).to eq "own config dir"
    end
  end

  specify "Loading a deeply nested slice from a slice class in its own config dir" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      # It does NOT look up "grandparent" (or above) configs; only the parent and the app
      write "slices/main/config/slices/deeply/nested.rb", <<~RUBY
        raise "This should not be loaded"
      RUBY

      write "slices/main/slices/deeply/slices/nested/config/slice.rb", <<~RUBY
        module Main
          module Deeply
            module Nested
              class Slice < Hanami::Slice
                def self.loaded_from = "own config dir"
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main].slices[:deeply].slices[:nested]).to be Main::Deeply::Nested::Slice
      expect(Hanami.app.slices[:main].slices[:deeply].slices[:nested].loaded_from).to eq "own config dir"
    end
  end

  specify "Loading a nested slice from a slice class in its parent's config dir, in preference to a slice class in its own config dir" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/main/config/slices/nested.rb", <<~RUBY
        require "hanami"

        module Main
          module Nested
            class Slice < Hanami::Slice
              def self.loaded_from = "parent config dir"
            end
          end
        end
      RUBY

      write "slices/main/slices/nested/config/slice.rb", <<~RUBY
        raise "This should not be loaded"
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main]).to be Main::Slice
      expect(Hanami.app.slices[:main].slices[:nested].loaded_from).to eq "parent config dir"
    end
  end

  specify "Loading a deeply nested slice from a slice class in its parent's config dir, in preference to a slice class in its own config dir" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      # It does NOT look up "grandparent" (or above) configs; only the parent and the app
      write "slices/main/config/slices/deeply/nested.rb", <<~RUBY
        raise "This should not be loaded"
      RUBY

      write "slices/main/slices/deeply/config/slices/nested.rb", <<~RUBY
        module Main
          module Deeply
            module Nested
              class Slice < Hanami::Slice
                def self.loaded_from = "parent config dir"
              end
            end
          end
        end
      RUBY

      write "slices/main/slices/deeply/slices/nested/config/slice.rb", <<~RUBY
        raise "This should not be loaded"
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main].slices[:deeply].slices[:nested]).to be Main::Deeply::Nested::Slice
      expect(Hanami.app.slices[:main].slices[:deeply].slices[:nested].loaded_from).to eq "parent config dir"
    end
  end

  specify "Loading a nested slice from a slice class in the app's config dir, in preference to a slice class in the slice's parent config dir or the slice's own config dir" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/slices/main/nested.rb", <<~RUBY
        require "hanami"

        module Main
          module Nested
            class Slice < Hanami::Slice
              def self.loaded_from = "app config dir"
            end
          end
        end
      RUBY

      write "slices/main/config/slices/nested.rb", <<~RUBY
        raise "This should not be loaded"
      RUBY

      write "slices/main/slices/nested/config/slice.rb", <<~RUBY
        raise "This should not be loaded"
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main]).to be Main::Slice
      expect(Hanami.app.slices[:main].slices[:nested].loaded_from).to eq "app config dir"
    end
  end

  specify "Loading a deeply nested slice from a slice class in the app's config dir, in preference to a slice class in the slice's parent config dir or the slice's own config dir" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/slices/main/deeply/nested.rb", <<~RUBY
        module Main
          module Deeply
            module Nested
              class Slice < Hanami::Slice
                def self.loaded_from = "app config dir"
              end
            end
          end
        end
      RUBY

      write "slices/main/config/slices/deeply/nested.rb", <<~RUBY
        raise "This should not be loaded"
      RUBY

      write "slices/main/slices/deeply/slices/nested/config/slice.rb", <<~RUBY
        raise "This should not be loaded"
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main].slices[:deeply].slices[:nested]).to be Main::Deeply::Nested::Slice
      expect(Hanami.app.slices[:main].slices[:deeply].slices[:nested].loaded_from).to eq "app config dir"
    end
  end

  specify "Loading a slice generates a slice class if none is defined" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/main/lib/foo.rb", <<~RUBY
        module Main
          class Foo; end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main]).to be Main::Slice
    end
  end

  specify "Registering a slice on the app creates a slice class with a top-level namespace" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            register_slice :main
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main]).to be Main::Slice
      expect(Main::Slice.ancestors).to include(Hanami::Slice)
    end
  end

  specify "Registering a nested slice creates a slice class within the parent's namespace" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/slices/main.rb", <<~RUBY
        module Main
          class Slice < Hanami::Slice
            register_slice :nested
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main].slices[:nested]).to be Main::Nested::Slice
    end
  end

  specify "Registering a nested slice with an existing class uses that class' own namespace" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/slices/main.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
          end
        end

        module Main
          class Slice < Hanami::Slice
            register_slice :nested, Admin::Slice
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main].slices[:nested]).to be Admin::Slice
    end
  end

  specify "Registering a slice with a block creates a slice class and evals the block" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            register_slice :main do
              register "greeting", "hello world"
            end
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:main]).to be Main::Slice
      expect(Main::Slice["greeting"]).to eq "hello world"
    end
  end
end
