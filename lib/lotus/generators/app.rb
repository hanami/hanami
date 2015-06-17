require 'shellwords'
require 'lotus/generators/abstract'
require 'lotus/generators/slice'

module Lotus
  module Generators
    class App < Abstract
      def initialize(command)
        super

        options.merge!(app_name_options)
        @slice_generator       = Slice.new(command)

        cli.class.source_root(source)
      end

      def start
        @slice_generator.start
      end

      private

      # @since x.x.x
      # @api private
      def app_name_options
        {
          application: app_name,
          application_base_url: application_base_url
        }
      end

      # @since x.x.x
      # @api private
      def application_base_url
        options[:application_base_url] || "/#{app_name}"
      end
    end
  end
end
