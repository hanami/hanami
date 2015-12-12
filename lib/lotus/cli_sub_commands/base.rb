module Lotus
  class CliSubCommands
    # Base class for cli sub commands
    #
    # @since x.x.x
    # @api private
    class Base < Thor
      include Thor::Actions

      private
      # Invoke help action for given command if exists
      # or execute the code inside block
      #
      # @param command [String] command to execute help action
      #
      # @since x.x.x
      # @api private
      def invoke_help_action_or(command)
        if options[:help]
          invoke :help, [command]
        else
          yield
        end
      end
    end
  end
end
