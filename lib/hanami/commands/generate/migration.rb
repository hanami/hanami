require 'hanami/commands/generate/abstract'

module Hanami
  module Commands
    class Generate
      class Migration < Abstract

        attr_reader :name, :underscored_name

        # @since 0.6.0
        # @api private
        #
        # @example
        #   20150612160502
        TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'.freeze

        # @since 0.6.0
        # @api private
        #
        # @example
        #   20150612160502_create_books.rb
        FILENAME_PATTERN = '%{timestamp}_%{name}.rb'.freeze

        def initialize(options, name)
          super(options)

          @name = name
          @underscored_name = Utils::String.new(@name).underscore

          environment.require_application_environment
          assert_migration_name!
        end

        def map_templates
          add_mapping('migration.rb.tt', destination_path)
        end

        private

        def destination_path
          existing_migration_path || new_migration_path
        end

        def existing_migration_path
          Dir.glob("#{Hanami::Model.configuration.migrations}/[0-9]*_#{underscored_name}.rb").first
        end

        def new_migration_path
          timestamp = Time.now.utc.strftime(TIMESTAMP_FORMAT)
          filename = FILENAME_PATTERN % { timestamp: timestamp, name: underscored_name}

          Hanami::Model.configuration.migrations.join(filename)
        end

        def assert_migration_name!
          if argument_blank?(name)
            raise ArgumentError.new('Migration name is missing')
          end
        end
      end
    end
  end
end
