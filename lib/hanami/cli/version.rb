# frozen_string_literal: true

require_relative "./command"

module Hanami
  module CLI
    class Version < Command
      def call(*)
        require "hanami/version"
        out.puts "v#{Hanami::VERSION}"
      end
    end
  end
end
