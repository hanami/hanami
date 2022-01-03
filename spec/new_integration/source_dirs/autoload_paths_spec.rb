RSpec.describe "Source dirs / autoload paths", :application_integration do
  specify "Default autoload paths are configured with the autoloader" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "slices/main/entities/post.rb", <<~RUBY
        module Main
          module Entities
            class Post
            end
          end
        end
      RUBY

      require "hanami/init"
      expect(Main::Entities::Post).to be
    end
  end

  specify "User-configured autoload paths are configured with the autoloader" do
    write "config/application.rb", <<~RUBY
      require "hanami"

      module TestApp
        class Application < Hanami::Application
          config.source_dirs.autoload_paths = ["entities", "structs"]
        end
      end
    RUBY

    write "slices/main/entities/post.rb", <<~RUBY
      module Main
        module Entities
          class Post
          end
        end
      end
    RUBY

    write "slices/main/structs/post.rb", <<~RUBY
      module Main
        module Structs
          class Post
          end
        end
      end
    RUBY

    require "hanami/init"
    expect(Main::Entities::Post).to be
    expect(Main::Structs::Post).to be
  end
end
