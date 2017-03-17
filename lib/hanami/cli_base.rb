module Hanami
  # @api private
  module CliBase
    # Add new custom CLI command to special CLI class.
    # Please be careful. This is a private method that
    # can be deleted soon.
    #
    # @since 0.8.0
    # @api private
    #
    # @example Usage with Cli class
    #   require 'hanami'
    #   require 'hanami/cli'
    #
    #   Hanami::Cli.define_commands do
    #     desc 'custom', 'Generate a something'
    #     long_desc <<-EOS
    #       long description for your custom command
    #     EOS
    #     def custom
    #       if options[:help]
    #         invoke :help, ['auth']
    #       else
    #         # ...
    #       end
    #     end
    #   end
    def define_commands(&blk)
      class_eval(&blk) if block_given?
    end

    # @api private
    def banner(command, nspace = true, subcommand = false)
      super(command, nspace, namespace != 'hanami:cli')
    end

    # @api private
    def handle_argument_error(command, error, args, arity)
      name = [(namespace == 'hanami:cli' ? nil : namespace), command.name].compact.join(" ")

      msg = "ERROR: \"#{basename} #{name}\" was called with "
      msg << "no arguments"               if     args.empty?
      msg << "arguments " << args.inspect unless args.empty?
      msg << "\nUsage: #{banner(command).inspect}"

      raise Thor::InvocationError, msg
    end
  end
end
