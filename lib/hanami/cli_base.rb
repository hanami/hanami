module Hanami
  module CliBase
    # Add new custom CLI command to special CLI class
    #
    # @since x.x.x
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
  end
end
