require 'hanami/utils/files'
require_relative 'with_directory'

module RSpec
  module Support
    module WithTmpDirectory
      private

      def with_tmp_directory(dir = Pathname.new('tmp').join('aruba'))
        with_directory(dir) do
          yield
        end
      ensure
        Hanami::Utils::Files.delete_directory(dir)
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::WithTmpDirectory, type: :cli
end
