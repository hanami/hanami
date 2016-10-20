require_relative 'with_project'

module RSpec
  module Support
    module WithCleanEnvProject
      private

      def with_clean_env_project(project = "bookshelf", args = {})
        ::Bundler.with_clean_env do
          with_project(project, args) do
            yield
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::WithCleanEnvProject, type: :cli
end
