# frozen_string_literal: true

require "dry/system/loader"
require "hanami/utils/string"

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

      def call(app, path, _configuration, namespace)
        ::Kernel.require(path)

        view = constant(app, path)
        return unless view?(view)

        configure(view, namespace)
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

      def configure(view, namespace)
        view.config.template = template_name(view, namespace)
      end

      def template_name(view, namespace)
        tokens = Utils::String.transform(view.name, [:sub, /#{namespace}::/, ""], [:split, /::/])
        tokens.map { |token| Utils::String.underscore(token) }.join("/")
      end
    end
  end
end
