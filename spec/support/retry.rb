module RSpec
  module Support
    module Retry
      private

      def retry_exec(exception, &blk)
        attempts = 1

        begin
          sleep 1
          blk.call # rubocop:disable Performance/RedundantBlockCall
        rescue exception
          raise if attempts > 10
          attempts += 1
          retry
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Retry, type: :cli
end
