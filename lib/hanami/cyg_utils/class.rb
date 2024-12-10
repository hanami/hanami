# frozen_string_literal: true

require "hanami/cyg_utils/deprecation"

module Hanami
  module CygUtils
    # Class utilities
    # @since 0.1.0
    class Class
      # Loads a class for the given name.
      #
      # @param name [String, Class] the specific class name
      # @param namespace [Class, Module] the Ruby namespace where we want to perform the lookup.
      # @return [Class, Module] the found Ruby constant.
      #
      # @raise [NameError] if no constant can be found.
      #
      # @since 0.1.0
      #
      # @example
      #   require 'hanami/cyg_utils/class'
      #
      #   module App
      #     module Service
      #       class Endpoint
      #       end
      #     end
      #
      #     class ServiceEndpoint
      #     end
      #   end
      #
      #   # basic usage
      #   Hanami::CygUtils::Class.load!('App::Service') # => App::Service
      #   Hanami::CygUtils::Class.load!(App::Service)   # => App::Service
      #
      #   # with explicit namespace
      #   Hanami::CygUtils::Class.load!('Service', App) # => App::Service
      #
      #   # with missing constant
      #   Hanami::CygUtils::Class.load!('Unknown') # => raises NameError
      def self.load!(name, namespace = Object)
        namespace.const_get(name.to_s, false)
      end

      # Loads a class for the given name, only if it's defined.
      #
      # @param name [String, Class] the specific class name
      # @param namespace [Class, Module] the Ruby namespace where we want to perform the lookup.
      # @return [Class, Module, NilClass] the Ruby constant, or nil if not found.
      #
      # @since 0.8.0
      #
      # @example
      #   require 'hanami/cyg_utils/class'
      #
      #   module App
      #     module Service
      #       class Endpoint
      #       end
      #     end
      #
      #     class ServiceEndpoint
      #     end
      #   end
      #
      #   # basic usage
      #   Hanami::CygUtils::Class.load('App::Service') # => App::Service
      #   Hanami::CygUtils::Class.load(App::Service)   # => App::Service
      #
      #   # with explicit namespace
      #   Hanami::CygUtils::Class.load('Service', App) # => App::Service
      def self.load(name, namespace = Object)
        load!(name, namespace) if namespace.const_defined?(name.to_s, false)
      end

      # Loads a class from the given pattern name and namespace
      #
      # @param pattern [String] the class name pattern
      # @param namespace [Class, Module] the Ruby namespace where we want to perform the lookup.
      # @return [Class, Module] the found Ruby constant.
      #
      # @raise [NameError] if no constant can be found.
      #
      # @since 0.3.1
      #
      # @see Hanami::CygUtils::String#tokenize
      #
      # @example
      #   require 'hanami/cyg_utils/class'
      #
      #   module App
      #     module Service
      #       class Endpoint
      #       end
      #     end
      #
      #     class ServiceEndpoint
      #     end
      #   end
      #
      #   # basic usage
      #   Hanami::CygUtils::Class.load_from_pattern!('App::Service') # => App::Service
      #
      #   # with explicit namespace
      #   Hanami::CygUtils::Class.load_from_pattern!('Service', App) # => App::Service
      #
      #   # with pattern
      #   Hanami::CygUtils::Class.load_from_pattern!('App::Service(::Endpoint|Endpoint)') # => App::Service::Endpoint
      #   Hanami::CygUtils::Class.load_from_pattern!('App::Service(Endpoint|::Endpoint)') # => App::ServiceEndpoint
      #
      #   # with missing constant
      #   Hanami::CygUtils::Class.load_from_pattern!('Unknown') # => raises NameError
      def self.load_from_pattern!(pattern, namespace = Object)
        Deprecation.new("Hanami::CygUtils::Class.load_from_pattern! is deprecated, please use Hanami::CygUtils::Class.load! instead") # rubocop:disable Layout/LineLength

        tokenize(pattern) do |token|
          begin
            return namespace.const_get(token, false)
          rescue NameError # rubocop:disable Lint/SuppressedException
          end
        end

        full_name = [(namespace == Object ? nil : namespace), pattern].compact.join("::")
        raise NameError.new("uninitialized constant #{full_name}")
      end

      def self.tokenize(pattern)
        if match = TOKENIZE_REGEXP.match(pattern)
          pre  = match.pre_match
          post = match.post_match
          tokens = match[1].split(TOKENIZE_SEPARATOR)
          tokens.each do |token|
            yield("#{pre}#{token}#{post}")
          end
        else
          yield(pattern)
        end

        nil
      end

      # Regexp for .tokenize
      #
      # @since 1.3.0
      # @api private
      TOKENIZE_REGEXP = /\((.*)\)/.freeze

      # Separator for .tokenize
      #
      # @since 1.3.0
      # @api private
      TOKENIZE_SEPARATOR = "|"
    end
  end
end
