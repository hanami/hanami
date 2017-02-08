require 'pathname'
require_relative 'with_directory'
require_relative 'env'

module RSpec
  module Support
    module WithinProjectDirectory
      private

      def within_project_directory(project)
        cd(project.to_s) do
          # Aruba resets ENV and its API to set new env vars is broken.
          #
          # We need to manually setup the following env vars:
          #
          # ENV["PATH"] is required by Capybara's selenium/poltergeist drivers
          ENV["PATH"] = RSpec::Support::Env.fetch_from_original("PATH")
          # Bundler on CI can't find HOME and it fails to run Hanami commands
          ENV["HOME"] = RSpec::Support::Env.fetch_from_original("HOME")

          yield
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::WithinProjectDirectory
end
