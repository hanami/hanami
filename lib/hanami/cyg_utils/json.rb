# frozen_string_literal: true

begin
  require "multi_json"
rescue LoadError
  require "json"
end

module Hanami
  module CygUtils
    # JSON wrapper
    #
    # If you use MultiJson gem this wrapper will use it.
    # Otherwise - JSON std lib.
    #
    # @since 0.8.0
    module Json
      # MultiJson adapter
      #
      # @since 0.9.1
      # @api private
      class MultiJsonAdapter
        # @since 0.9.1
        # @api private
        def parse(payload)
          MultiJson.load(payload)
        end

        # @since 0.9.1
        # @api private
        def generate(object)
          MultiJson.dump(object)
        end
      end

      # rubocop:disable Style/ClassVars
      if defined?(MultiJson)
        @@engine    = MultiJsonAdapter.new
        ParserError = MultiJson::ParseError
      else
        @@engine    = ::JSON
        ParserError = ::JSON::ParserError
      end
      # rubocop:enable Style/ClassVars

      # Parses the given JSON paylod
      #
      # @param payload [String] a JSON payload
      #
      # @return [Object] the result of the loading process
      #
      # @raise [Hanami::CygUtils::Json::ParserError] if the paylod is invalid
      #
      # @since 0.9.1
      def self.parse(payload)
        @@engine.parse(payload)
      end

      # Generate a JSON document from the given object
      #
      # @param object [Object] any object
      #
      # @return [String] the result of the dumping process
      #
      # @since 0.9.1
      def self.generate(object)
        @@engine.generate(object)
      end
    end
  end
end
