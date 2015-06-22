require 'lotus/generators/abstract'
require 'lotus/utils/string'

module Lotus
  module Generators
    # @since 0.4.0
    # @api private
    class Migration < Abstract
      # @since 0.4.0
      # @api private
      #
      # @example
      #   20150612160502
      TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'.freeze

      # @since 0.4.0
      # @api private
      #
      # @example
      #   20150612160502_create_books.rb
      FILENAME = '%{timestamp}_%{name}.rb'.freeze

      # @since 0.4.0
      # @api private
      def initialize(command)
        super

        timestamp = Time.now.utc.strftime(TIMESTAMP_FORMAT)
        filename  = FILENAME % { timestamp: timestamp, name: name }

        env.require_application_environment
        @destination = Lotus::Model.configuration.migrations.join(filename)

        cli.class.source_root(source)
      end

      # @since 0.4.0
      # @api private
      def start
        templates = {
          'migration.rb.tt' => @destination
        }

        templates.each do |src, dst|
          cli.template(source.join(src), target.join(dst), {})
        end
      end

      private

      # @since 0.4.0
      # @api private
      def name
        Utils::String.new(app_name || super).underscore
      end
    end
  end
end
