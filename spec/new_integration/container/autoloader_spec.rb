RSpec.describe "App autoloader", :app_integration do
  specify "Classes are autoloaded through direct reference, including through components resolved from the container" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            # Use a custom inflection to ensure this is respected by the autoloader
            config.inflections do |inflections|
              inflections.acronym "NBA"
            end
          end
        end
      RUBY

      write "lib/non_app/thing.rb", <<~RUBY
        module NonApp
          class Thing
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

      write "slices/admin/lib/operations/create_game.rb", <<~RUBY
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

      write "slices/admin/lib/entities/game.rb", <<~RUBY
        # auto_register: false

        module Admin
          module Entities
            class Game
            end
          end
        end
      RUBY

      write "slices/admin/lib/entities/quarter.rb", <<~RUBY
        # auto_register: false

        module Admin
          module Entities
            class Quarter
            end
          end
        end
      RUBY

      require "hanami/prepare"

      expect(require("non_app/thing")).to be true
      expect(NonApp::Thing).to be

      expect(TestApp::NBAJam::GetThatOuttaHere).to be

      expect(Admin::Slice["operations.create_game"]).to be_an_instance_of(Admin::Operations::CreateGame)
      expect(Admin::Slice["operations.create_game"].call).to be_an_instance_of(Admin::Entities::Game)

      expect(Admin::Entities::Quarter).to be
    end
  end
end
