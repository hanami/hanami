module Hanami
  module Components
    module App
      class View
        def self.resolve(app)
          config    = app.configuration
          namespace = app.namespace

          unless namespace.const_defined?('View', false)
            view = Hanami::View.duplicate(namespace) do
              root   config.templates
              layout config.layout

              config.view.__apply(self)
            end

            namespace.const_set('View', view)
          end
        end
      end
    end
  end
end
