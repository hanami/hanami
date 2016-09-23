require 'pathname'
require_relative 'with_directory'

module RSpec
  module Support
    module WithinProjectDirectory
      private

      def within_project_directory(project)
        cd(project) do
          yield
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::WithinProjectDirectory
end
