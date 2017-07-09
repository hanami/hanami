module Hanami
  module CommandLine
    class Version
      include Hanami::Cli::Command

      register "version"
      aliases '--version', '-v'

      def call
        puts "v#{Hanami::VERSION}"
      end
    end
  end
end
