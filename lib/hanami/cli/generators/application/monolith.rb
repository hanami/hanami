# frozen_string_literal: true

require "erb"

module Hanami
  module CLI
    module Generators
      class Context
        def initialize(inflector, app)
          @inflector = inflector
          @app = app
        end

        def ctx
          binding
        end

        def hanami_version
          Hanami::Version.gem_requirement
        end

        def classified_app_name
          inflector.classify(app)
        end

        def underscored_app_name
          inflector.underscore(app)
        end

        private

        attr_reader :inflector

        attr_reader :app
      end

      module Application
        class Monolith
          def initialize(fs:, inflector:)
            super()
            @fs = fs
            @inflector = inflector
          end

          def call(app, context: Context.new(inflector, app))
            fs.write(".env", t("env.erb", context))

            fs.write("README.md", t("readme.erb", context))
            fs.write("Gemfile", t("gemfile.erb", context))
            fs.write("Rakefile", t("rakefile.erb", context))
            fs.write("config.ru", t("config_ru.erb", context))

            fs.write("config/application.rb", t("application.erb", context))
            fs.write("config/settings.rb", t("settings.erb", context))
            fs.write("config/routes.rb", t("routes.erb", context))

            fs.write("lib/#{app}/types.rb", t("types.erb", context))
          end

          private

          attr_reader :fs

          attr_reader :inflector

          def template(path, context)
            require "erb"

            ERB.new(
              File.read(__dir__ + "/monolith/#{path}")
            ).result(context.ctx)
          end

          alias_method :t, :template
        end
      end
    end
  end
end
