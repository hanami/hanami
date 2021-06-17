RSpec.describe "Application autoloader", :application_integration do
  specify "Classes are autoloaded through direct reference, including through components resolved from the container" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
            # Use a custom inflection to ensure this is respected by the autoloader
            config.inflector do |inflections|
              inflections.acronym "NBA"
            end
          end
        end
      RUBY

      write "lib/test_app/nba_jam/get_that_outta_here.rb", <<~RUBY
        module TestApp
          module NBAJam
            class GetThatOuttaHere
            end
          end
        end
      RUBY

      write "slices/admin/lib/admin/operations/create_game.rb", <<~RUBY
        module Admin
          module Operations
            class CreateGame
              def call
                Entities::Game.new
              end
            end
          end
        end
      RUBY

      write "slices/admin/lib/admin/entities/game.rb", <<~RUBY
        # auto_register: false

        module Admin
          module Entities
            class Game
            end
          end
        end
      RUBY

      write "slices/admin/lib/admin/entities/quarter.rb", <<~RUBY
        # auto_register: false

        module Admin
          module Entities
            class Quarter
            end
          end
        end
      RUBY

      require "hanami/init"

      expect(TestApp::NBAJam::GetThatOuttaHere).to be
      expect(Admin::Slice["operations.create_game"]).to be_an_instance_of(Admin::Operations::CreateGame)
      expect(Admin::Slice["operations.create_game"].call).to be_an_instance_of(Admin::Entities::Game)
      expect(Admin::Entities::Quarter).to be
    end
  end

  specify "Autoloading can be disabled" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
            config.autoloader = false
          end
        end
      RUBY

      write "lib/test_app/nba_jam/get_that_outta_here.rb", <<~RUBY
        module TestApp
          module NBAJam
            class GetThatOuttaHere
            end
          end
        end
      RUBY

      write "slices/admin/lib/admin/operations/create_game.rb", <<~RUBY
        require "admin/entities/game"

        module Admin
          module Operations
            class CreateGame
              def call
                Entities::Game.new
              end
            end
          end
        end
      RUBY

      write "slices/admin/lib/admin/entities/game.rb", <<~RUBY
        # auto_register: false

        module Admin
          module Entities
            class Game
            end
          end
        end
      RUBY

      write "slices/admin/lib/admin/entities/quarter.rb", <<~RUBY
        # auto_register: false

        module Admin
          module Entities
            class Quarter
            end
          end
        end
      RUBY

      require "hanami/init"

      expect { TestApp::NBAJam::GetThatOuttaHere }.to raise_error NameError
      require "test_app/nba_jam/get_that_outta_here"
      expect(TestApp::NBAJam::GetThatOuttaHere).to be

      expect(Admin::Slice["operations.create_game"]).to be_an_instance_of(Admin::Operations::CreateGame)
      expect(Admin::Slice["operations.create_game"].call).to be_an_instance_of(Admin::Entities::Game)

      expect { Admin::Entities::Quarter }.to raise_error NameError
      require "admin/entities/quarter"
      expect(Admin::Entities::Quarter).to be
    end
  end
end
