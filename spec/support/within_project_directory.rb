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
          # ENV["PATH"] is required by Capybara's selenium/poltergeist drivers
          ENV["PATH"] = RSpec::Support::Env.fetch_from_original("PATH")

          yield
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::WithinProjectDirectory
end
