require 'hanami/commands/generate/abstract'
require 'hanami/utils/file_list'

module Hanami
  # @api private
  module Commands
    # @api private
    class Generate
      # @api private
      class Migration < Abstract
        # @api private
        attr_reader :name
        # @api private
        attr_reader :underscored_name

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

        # @api private
        def initialize(options, name)
          super(options)

          @name = name
          @underscored_name = Utils::String.new(@name).underscore

          Components.resolve('model.configuration')
          assert_migration_name!
        end

        # @api private
        def map_templates
          add_mapping('migration.rb.tt', destination_path)
        end

        private

        # @api private
        def destination_path
          existing_migration_path || new_migration_path
        end

        # @api private
        def existing_migration_path
          Utils::FileList["#{Hanami::Model.configuration.migrations}/[0-9]*_#{underscored_name}.rb"].first
        end

        # @api private
        def new_migration_path
          timestamp = Time.now.utc.strftime(TIMESTAMP_FORMAT)
          filename = FILENAME_PATTERN % { timestamp: timestamp, name: underscored_name}

          Hanami::Model.configuration.migrations.join(filename)
        end

        # @api private
        def assert_migration_name!
          if argument_blank?(name)
            raise ArgumentError.new('Migration name is missing')
          end
        end
      end
    end
  end
end
