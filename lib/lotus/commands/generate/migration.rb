require 'lotus/commands/generate/abstract'

module Lotus
  module Commands
    class Generate
      class Migration < Abstract
        # @since x.x.x
        # @api private
        #
        # @example
        #   20150612160502
        TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'.freeze

        # @since x.x.x
        # @api private
        #
        # @example
        #   20150612160502_create_books.rb
        FILENAME_PATTERN = '%{timestamp}_%{name}.rb'.freeze

        def initialize(options, migration_name)
          super(options)
          @migration_name = migration_name

          environment.require_application_environment
          assert_migration_name!
        end

        def map_templates
          destination_path = Lotus::Model.configuration.migrations.join(filename)
          add_mapping('migration.rb.tt', destination_path)
        end

        private

        def filename
          timestamp = Time.now.utc.strftime(TIMESTAMP_FORMAT)
          underscored_migration_name = Utils::String.new(@migration_name).underscore

          FILENAME_PATTERN % { timestamp: timestamp, name: underscored_migration_name}
        end

        def assert_migration_name!
          if @migration_name.nil? || @migration_name.strip.empty?
            raise ArgumentError.new('Migration name nil or empty')
          end
        end
      end
    end
  end
end
