# frozen_string_literal: true

module RSpec
  module Support
    module Logging
      # Strips ANSI escape sequences from a string, useful for asserting against colorized log
      # output without needing to account for terminal color codes.
      def strip_ansi(str)
        str.gsub(/\e\[[0-9;]*m/, "")
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Logging
end
