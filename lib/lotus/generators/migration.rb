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
          #app_name:         app_name,
          migration_name:   migration_name,
          migration_time:   migration_time,
          migration_class:  migration_class,
        }

        templates = {
          'migration.rb.tt' => "db/migrate/#{ opts[:migration_time] }_#{ opts[:migration_name] }.rb"
        }

        templates.each do |src, dst|
          cli.template(source.join(src), target.join(dst), opts)
        end
      end
    end
  end
end
