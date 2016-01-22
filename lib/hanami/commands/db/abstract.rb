module Hanami
  module Commands
    class DB
      class Abstract
        attr_reader :environment

        def initialize(options)
          @options = options
          @environment = Hanami::Environment.new(options)
          @environment.require_application_environment
        end

        def start
          raise NotImplementedError
        end
      end
    end
  end
end
