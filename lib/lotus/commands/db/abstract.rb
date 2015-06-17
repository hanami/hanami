module Lotus
  module Commands
    class DB
      class Abstract
        def initialize(environment)
          environment.require_application_environment
        end

        def start
          raise NotImplementedError
        end
      end
    end
  end
end
