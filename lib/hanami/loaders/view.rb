# frozen_string_literal: true

require "dry/system/loader"

module Hanami
  module Loaders
    # Action loader
    #
    # @api private
    # @since 2.0.0
    class View
      def initialize(inflector)
        @inflector = inflector
      end

      def call(app, path, _configuration)
        ::Kernel.require(path)

        view = constant(app, path)
        return unless view?(view)

        configure(view)
        view.new
      end

      private

      attr_reader :inflector

      def constant(app, path)
        Dry::System::Loader.new(relative_path(app, path), inflector).constant
      end

      def view?(klass)
        klass.ancestors.include?(Hanami::View)
      end

      def relative_path(app, path)
        path.sub(/(.*)#{app}/, app.to_s).sub(".rb", "")
      end

      def configure(view)
        view.config.template = "home/index"
      end
    end
  end
end
