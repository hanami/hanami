require 'hanami/assets'

module Hanami
  module Commands
    class Assets
      class Precompile
        def initialize(options, environment)
          @options     = options
          @environment = environment
        end

        def start
          preload_applications
          precompile
        end

        private

        def preload_applications
          @environment.require_application_environment

          if @environment.container?
            Hanami::Container.new
          else
            Hanami::Application.preload!
          end
        end

        def precompile
          Hanami::Assets.deploy
        end
      end
    end
  end
end
