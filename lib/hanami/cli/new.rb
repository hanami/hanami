# frozen_string_literal: true

require_relative "./command"
require "hanami/cli/generators/application"

module Hanami
  module CLI
    class New < Command
      ARCHITECTURES = %w[monolith micro].freeze
      private_constant :ARCHITECTURES

      DEFAULT_ARCHITECTURE = ARCHITECTURES.first
      private_constant :DEFAULT_ARCHITECTURE

      argument :app, required: true, desc: "The application name"

      option :architecture, alias: "arch", default: DEFAULT_ARCHITECTURE,
                            values: ARCHITECTURES, desc: "The architecture"

      def call(app:, architecture: DEFAULT_ARCHITECTURE, **)
        app = inflector.underscore(app)

        out.puts "generating #{app}"

        fs.mkdir(app)
        fs.chdir(app) do
          generator(architecture).call(app)
        end
      end

      private

      def generator(architecture)
        raise ArgumentError.new("unknown architecture `#{architecture}'") unless ARCHITECTURES.include?(architecture)

        Generators::Application[architecture, fs, inflector]
      end
    end
  end
end
