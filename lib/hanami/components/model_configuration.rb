module Hanami
  module Components
    # Model configuration
    #
    # @since x.x.x
    class ModelConfiguration < Component
      register_as 'model.configuration'

      def resolve
        require 'hanami/model'

        Hanami::Model.configure(&configuration.model)
        Hanami::Model.configuration
      rescue LoadError # rubocop:disable Lint/HandleExceptions
      end
    end
  end
end
