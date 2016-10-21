module RSpec
  module Support
    module Retry
      private

      def retry_exec(exception) # rubocop:disable Metrics/MethodLength
        attempts           = 1
        max_retry_attempts = Platform.match do
          engine(:ruby)  { 10 }
          engine(:jruby) { 20 }
        end

        begin
          sleep 1
          yield
        rescue exception
          raise if attempts > max_retry_attempts
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
