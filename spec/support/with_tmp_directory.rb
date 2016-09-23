require 'fileutils'
require_relative 'with_directory'

module RSpec
  module Support
    module WithTmpDirectory
      private

      def with_tmp_directory
        dir = Dir.mktmpdir

        with_directory(dir) do
          yield
        end
      ensure
        FileUtils.rm_rf(dir)
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::WithTmpDirectory, type: :cli
end
