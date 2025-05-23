# frozen_string_literal: true

module Hanami
  class Config
    class Actions
      # Config for Content Security Policy in Hanami apps
      #
      # @since 2.0.0
      class ContentSecurityPolicy
        # @since 2.0.0
        # @api private
        def initialize(&blk)
          @policy = {
            base_uri: "'self'",
            child_src: "'self'",
            connect_src: "'self'",
            default_src: "'none'",
            font_src: "'self'",
            form_action: "'self'",
            frame_ancestors: "'self'",
            frame_src: "'self'",
            img_src: "'self' https: data:",
            media_src: "'self'",
            object_src: "'none'",
            script_src: "'self'",
            style_src: "'self' 'unsafe-inline' https:"
          }

          blk&.(self)
        end

        # @since 2.0.0
        # @api private
        def initialize_copy(original_object)
          @policy = original_object.instance_variable_get(:@policy).dup
          super
        end

        # Get a CSP setting
        #
        # @param key [Symbol] the underscored name of the CPS setting
        # @return [String,NilClass] the CSP setting, if any
        #
        # @since 2.0.0
        # @api public
        #
        # @example
        #   module MyApp
        #     class App < Hanami::App
        #       config.actions.content_security_policy[:base_uri] # => "'self'"
        #     end
        #   end
        def [](key)
          @policy[key]
        end

        # Set a CSP setting
        #
        # @param key [Symbol] the underscored name of the CPS setting
        # @param value [String] the CSP setting value
        #
        # @since 2.0.0
        # @api public
        #
        # @example Replace a default value
        #   module MyApp
        #     class App < Hanami::App
        #       config.actions.content_security_policy[:plugin_types] = nil
        #     end
        #   end
        #
        # @example Append to a default value
        #   module MyApp
        #     class App < Hanami::App
        #       config.actions.content_security_policy[:script_src] += " https://my.cdn.test"
        #     end
        #   end
        def []=(key, value)
          @policy[key] = value
        end

        # Deletes a CSP key
        #
        # @param key [Symbol] the underscored name of the CPS setting
        #
        # @since 2.0.0
        # @api public
        #
        # @example
        #   module MyApp
        #     class App < Hanami::App
        #       config.actions.content_security_policy.delete(:object_src)
        #     end
        #   end
        def delete(key)
          @policy.delete(key)
        end

        # Returns true if 'nonce' is used in any of the policies.
        #
        # @return [Boolean]
        #
        # @api public
        # @since x.x.x
        def nonce?
          @policy.any? { _2.match?(/'nonce'/) }
        end

        # Returns an array of middleware name to support 'nonce' in
        # policies, or an empty array if 'nonce' is not used.
        #
        # @return [Array<(Symbol, Array)>]
        #
        # @api public
        # @since x.x.x
        def middleware
          return [] unless nonce?

          [Hanami::Middleware::ContentSecurityPolicyNonce]
        end

        # @since 2.0.0
        # @api private
        def to_s
          @policy.map do |key, value|
            "#{dasherize(key)} #{value}"
          end.join(";")
        end

        private

        # @since 2.0.0
        # @api private
        def dasherize(key)
          key.to_s.gsub("_", "-")
        end
      end
    end
  end
end
