# frozen_string_literal: true

require "hanami/action"
require "dry/system/loader"

module Hanami
  module Loaders
    # Action loader
    #
    # @api private
    # @since 2.0.0
    class Action
      def initialize(inflector)
        @inflector = inflector
      end

      def call(app, path, configuration)
        ::Kernel.require(path)

        action = constant(app, path)
        return unless action?(action)

        action.new(configuration: configuration)
      end

      private

      attr_reader :inflector

      def constant(app, path)
        Dry::System::Loader.new(relative_path(app, path), inflector).constant
      end

      def action?(klass)
        klass.ancestors.include?(Hanami::Action)
      end

      def relative_path(app, path)
        path.sub(/(.*)#{app}/, app.to_s).sub(".rb", "")
      end
    end
  end
end
