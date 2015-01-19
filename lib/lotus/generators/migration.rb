require 'lotus/generators/abstract'

module Lotus
  module Generators
    class Migration < Abstract
      def initialize(command)
        super
        cli.class.source_root(source)
      end

      def start
        opts = {
          migration_file:   migration_file,
          migration_class:  migration_class,
        }

        templates = {
          'migration.rb.tt' => "db/migrate/#{ opts[:migration_file] }.rb"
        }

        templates.each do |src, dst|
          cli.template(source.join(src), target.join(dst), opts)
        end
      end

      private

      def migration_file
        "#{migration_time}_#{migration_name}"
      end
    end
  end
end
