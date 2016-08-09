module Hanami
  module I18n
    class I18nWithApplicationScope
      def initialize(scope)
        @scope = scope
      end

      def translate(key, original_options = {})
        if !original_options.key?(:scope)
          scoped_options = original_options.merge(scope: scope, throw: true)
        end
        catch(:exception) do
          return ::I18n.translate(key, scoped_options)
        end
        # Could not find a scoped translation, try to find an unscoped one
        ::I18n.translate(key, original_options)
      end

      alias_method :t, :translate

      private

      attr_reader :scope
    end
  end
end
