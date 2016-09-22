require 'pathname'

module RSpec
  module Support
    module WithProject
      private

      def with_project
        dir = Dir.mktmpdir

        with_directory(dir) do
          _create_project
          _bundle
          yield
        end
      ensure
        FileUtils.rm_rf(dir)
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
  config.include RSpec::Support::WithProject
end
