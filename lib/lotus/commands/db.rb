module Lotus
  module Commands
    class DB < Thor
      namespace :db

      desc 'db console', 'start DB console'

      desc 'console', 'start DB console'
      method_option :environment, desc: 'path to environment configuration (config/environment.rb)'

      def console(name = nil)
        if options[:help]
          invoke :help, ['console']
        else
          require 'lotus/commands/db/console'
          Lotus::Commands::DB::Console.new(name, environment).start
        end
      end

      desc 'migrate', 'run your migration'
      def migrate
        if options[:help] 
          invoke :help, ['migrate']
        else
          require 'lotus/commands/db/migrator'
          Lotus::Commands::DB::Migrator.new(environment).migrate
        end
      end
      
      desc 'rollback', 'rollback your migration'
      method_option :step, desc:'number of stpes to roll back', type: :numeric

      def rollback
        if options[:help] 
          invoke :help, ['rollback']
        else
          require 'lotus/commands/db/migrator'
          Lotus::Commands::DB::Migrator.new(environment).rollback
        end
      end
      private

      def environment
        Lotus::Environment.new(options)
      end
    end
  end
end
