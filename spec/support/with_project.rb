require_relative 'with_tmp_directory'

module RSpec
  module Support
    module WithProject
      private

      def with_project
        with_tmp_directory do
          _create_project
          _bundle
          yield
        end
      end

      def _create_project
        system "hanami new bookshelf", out: ::File::NULL
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
