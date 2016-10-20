require_relative 'with_clean_env_project'

module RSpec
  module Support
    module ProjectWithoutHanamiModel
      private

      def project_without_hanami_model(project = "bookshelf", args = {})
        with_clean_env_project(project, args.merge(exclude_gems: ["hanami-model"])) do
          replace "config/environment.rb", "hanami/model", ""
          yield
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::ProjectWithoutHanamiModel, type: :cli
end
