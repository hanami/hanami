module Hanami
  module Components
    # Model
    #
    # @since x.x.x
    class Model < Component
      register_as 'model'
      requires 'model.configuration'

      def resolve
        if defined?(Hanami::Model)
          Hanami::Model.load!
          true
        else
          false
        end
      end
    end
  end
end
