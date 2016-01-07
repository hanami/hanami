require 'lotus/assets'

module Lotus
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
            Lotus::Container.new
          else
            Lotus::Application.preload!
          end
        end

        def precompile
          Lotus::Assets.deploy
        end
      end
    end
  end
end
