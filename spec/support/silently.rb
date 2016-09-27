require 'tempfile'

module RSpec
  module Support
    def self.silently(cmd)
      out    = Tempfile.new('hanami-out')
      result = system(cmd, out: out.path)

      return if result

      out.rewind
      fail "#{cmd} failed:\n#{out.read}" # rubocop:disable Style/SignalException
    end

    module Silently
      private

      def silently(cmd)
        Support.silently(cmd)
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Silently, type: :cli
end
