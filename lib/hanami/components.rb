require 'concurrent'
require 'hanami/component'

module Hanami
  # Components
  #
  # @since x.x.x
  module Components
    # FIXME: review if this is the right data structure for @_components
    @_components = Concurrent::Hash.new
    @_resolved   = Concurrent::Map.new

    def self.register(name, component)
      @_components[name] = component
    end

    def self.resolved(name, value)
      @_resolved.merge_pair(name, value)
    end

    def self.resolve(names)
      names.each do |name|
        @_resolved.fetch_or_store(name) do
          component = @_components.fetch(name)
          component.new(Hanami.configuration).resolve
        end
      end
    end

    def self.[](name)
      @_resolved.fetch(name) do
        raise ArgumentError.new("Component not found: `#{name}'.\nAvailable components are: #{@_resolved.keys.join(', ')}")
      end
    end

    require 'hanami/components/all'
    require 'hanami/components/routes'
    require 'hanami/components/model'
    require 'hanami/components/model_configuration'
    require 'hanami/components/apps_configurations'
    require 'hanami/components/apps_assets_configurations'
  end
end
