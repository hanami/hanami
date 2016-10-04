require 'hanami/component'
require 'hanami/environment'

module Hanami
  module Commands
    # Abstract command
    #
    # @since x.x.x
    class Command < Component
      # @param options [Hash] Environment's options
      #
      # @since x.x.x
      def initialize(options)
        @environment = Hanami::Environment.new(options)
        @environment.require_project_environment

        super(Hanami.configuration)
      end

      private

      # @since x.x.x
      attr_reader :environment
    end
  end
end
