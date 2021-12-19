# frozen_string_literal: true

RSpec.describe "Container auto-registration", :application_integration do
  specify "Auto-registering files in slice source directories" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
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

      require "hanami/setup"
      Hanami.boot

      expect(Admin::Slice["nba_jam.get_that_outta_here"]).to be_an Admin::NBAJam::GetThatOuttaHere
    end
  end

  it "Unbooted application resolves components lazily from the lib/ directories" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
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

      require "hanami/init"

      expect(Admin::Slice.keys).not_to include("nba_jam.get_that_outta_here")
      expect(Admin::Slice["nba_jam.get_that_outta_here"]).to be_an Admin::NBAJam::GetThatOuttaHere
      expect(Admin::Slice.keys).to include("nba_jam.get_that_outta_here")
    end
  end
end
