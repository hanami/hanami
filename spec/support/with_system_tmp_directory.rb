require_relative 'with_tmp_directory'

module RSpec
  module Support
    module WithSystemTmpDirectory
      private

      def with_system_tmp_directory(&blk)
        with_tmp_directory(Dir.mktmpdir, &blk)
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::WithSystemTmpDirectory, type: :cli
end
