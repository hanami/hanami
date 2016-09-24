require_relative 'with_tmp_directory'
require_relative 'within_project_directory'

module RSpec
  module Support
    module WithProject
      private

      def with_project(project = "bookshelf", args = {})
        with_tmp_directory do
          _create_project(project, args)

          within_project_directory(project) do
            _bundle
            yield
          end
        end
      end

      def _create_project(project, args)
        system "hanami new #{project}#{_create_project_args(args)}", out: ::File::NULL
      end

      def _bundle
        system "bundle install", out: ::File::NULL
      end

      def _create_project_args(args)
        return if args.empty?

        result = args.map do |arg, value|
          "--#{arg}=#{value}"
        end.join(" ")

        " #{result}"
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::WithProject, type: :cli
end
