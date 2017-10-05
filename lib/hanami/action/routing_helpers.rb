require 'hanami/utils/string'

module Hanami
  module Action
    # Routing helper for full stack Hanami web applications.
    #
    # For a given application called <tt>Web::Application</tt>, at runtime
    # Hanami creates a routes factory called <tt>Web::Routes</tt>.
    #
    # Included by default in every controller.
    #
    # @since 0.3.2
    #
    # @example Usage in controller
    #   require 'hanami'
    #
    #   module Web::Controllers::Protected
    #     class Index
    #       include Web::Action
    #
    #       def call(params)
    #         redirect_to routes.root_path
    #       end
    #     end
    #   end
    module RoutingHelpers
      # @since 0.3.2
      #
      # @example
      #  module Web
      #    class Application
      #    end
      #  end
      #
      #  # Removes namespace and provide routes method
      #
      #  => factory = "#{Utils::String.new(Web::Application).namespace}.routes"
      #  => 'Application.routes'
      #
      #  # After that defines private method for Api::ExamplesController:
      #
      #  module Web
      #    class Application
      #      private
      #
      #      def routes
      #        ExamplesController.routes
      #      end
      #    end
      #  end
      def self.included(base)
        factory = "#{Utils::String.new(base).namespace}.routes"

        base.class_eval <<-END_EVAL, __FILE__, __LINE__
          private

          def routes
            #{factory}
          end
        END_EVAL
      end
    end
  end
end
