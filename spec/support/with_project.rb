require_relative 'with_tmp_directory'
require_relative 'within_project_directory'

module RSpec
  module Support
    module WithProject
      private

      def with_project(project = "bookshelf")
        with_tmp_directory do
          _create_project(project)

          within_project_directory(project) do
            _bundle
            yield
          end
        end
      end

      def _create_project(project)
        system "hanami new #{project}", out: ::File::NULL
      end

      def _bundle
        system "bundle install", out: ::File::NULL
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::WithProject, type: :cli
end
