# frozen_string_literal: true

RSpec.describe "Container auto-registration", :app_integration do
  specify "Auto-registering files in slice source directories" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.inflections do |inflections|
              inflections.acronym "NBA"
            end
          end
        end
      RUBY

      write "app/action.rb", <<~RUBY
        # auto_register: false
        require "hanami/action"

        module TestApp
          class Action < Hanami::Action
          end
        end
      RUBY

      write "app/actions/nba_rosters/index.rb", <<~RUBY
        module TestApp
          module Actions
            module NBARosters
              class Index < TestApp::Action
              end
            end
          end
        end
      RUBY

      write "slices/admin/lib/nba_jam/get_that_outta_here.rb", <<~RUBY
        module Admin
          module NBAJam
            class GetThatOuttaHere
            end
          end
        end
      RUBY

      require "hanami/setup"
      Hanami.boot

      expect(TestApp::App["actions.nba_rosters.index"]).to be_an TestApp::Actions::NBARosters::Index
      expect(Admin::Slice["nba_jam.get_that_outta_here"]).to be_an Admin::NBAJam::GetThatOuttaHere
    end
  end

  it "Unbooted app resolves components lazily from the lib/ directories" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.inflections do |inflections|
              inflections.acronym "NBA"
            end
          end
        end
      RUBY

      write "slices/admin/lib/nba_jam/get_that_outta_here.rb", <<~RUBY
        module Admin
          module NBAJam
            class GetThatOuttaHere
            end
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Admin::Slice.keys).not_to include("nba_jam.get_that_outta_here")
      expect(Admin::Slice["nba_jam.get_that_outta_here"]).to be_an Admin::NBAJam::GetThatOuttaHere
      expect(Admin::Slice.keys).to include("nba_jam.get_that_outta_here")
    end
  end
end
