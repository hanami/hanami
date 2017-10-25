require 'concurrent'

module Hanami
  # Components API
  #
  # Components are an internal Hanami that provides precise loading mechanism
  # for a project. It is responsible to load frameworks, configurations, code, etc..
  #
  # The implementation is thread-safe
  #
  # @example
  #   Hanami::Components.resolved('repo') { UserRepository.new }
  #   Hanami::Components['repository.users'] # => #<UserRepository relations=[...]>
  #
  # Also you can use Hanami::Components with dry-auto_inject
  #
  # @example
  #   Hanami::Components.resolved('repo') { UserRepository.new }
  #   Hanami::Components['repository.users'] # => #<UserRepository relations=[...]>
  #
  #   HanamiImport = Dry::AutoInject(Hanami::Components)
  #
  #   class CreateUser
  #     include HanamiImport['repository.users']
  #
  #     def call(payload)
  #       users.create(payload)
  #     end
  #   end
  #
  #   CreateUser.new.call # => #<User:...>
  #   CreateUser.new(users: MockRepository.new).call # => #<MockUser:...>
  #
  # @since 0.9.0
  # @api private
  module Components
    # Available components
    #
    # @since 0.9.0
    # @api private
    @_components = Concurrent::Hash.new

    # Resolved components
    #
    # @since 0.9.0
    # @api private
    @_resolved   = Concurrent::Map.new

    # Register a component
    #
    # @param name [String] the unique component name
    # @param blk [Proc] the logic of the component
    #
    # @since 0.9.0
    # @api private
    #
    # @see Hanami::Components::Component
    def self.register(name, &blk)
      @_components[name] = Component.new(name, &blk)
    end

    # Return a registered component
    #
    # @param name [String] the name of the component
    #
    # @raise [ArgumentError] if the component is unknown
    #
    # @since 0.9.0
    # @api private
    def self.component(name)
      @_components.fetch(name) do
        raise ArgumentError.new("Component not found: `#{name}'.\nAvailable components are: #{@_components.keys.join(', ')}")
      end
    end

    # Mark a component as resolved by providing a value or a block.
    # In the latter case, the returning value of the block is associated with
    # the component.
    #
    # @param name [String] the name of the component to mark as resolved
    # @param value [Object] the optional value of the component
    # @param blk [Proc] the optional block which returning value is associated with the component.
    #
    # @since 0.9.0
    # @api private
    def self.resolved(name, value = nil, &blk)
      if block_given?
        @_resolved.fetch_or_store(name, &blk)
      else
        @_resolved.compute_if_absent(name) { value }
      end
    end

    # Ask to resolve a component.
    #
    # This is used as dependency mechanism.
    # For instance `model` component depends on `model.configuration`. Before to
    # resolve `model`, `Components` uses this method to resolve that dependency first.
    #
    # @param names [String,Array<String>] one or more components to be resolved
    #
    # @since 0.9.0
    # @api private
    def self.resolve(*names)
      Array(names).flatten.each do |name|
        @_resolved.fetch_or_store(name) do
          component = @_components.fetch(name)
          component.call(Hanami.configuration)
        end
      end
    end

    # Return the value of an already resolved component. Or raise error for not resolved component.
    #
    # @example
    #   Hanami::Components.resolved('repository.users') { UserRepository.new }
    #
    #   Hanami::Components['repository.users'] # => #<UserRepository relations=[...]>
    #   Hanami::Components['repository.other'] # => error
    #
    # @param name [String] the component name
    #
    # @raise [ArgumentError] if the component is unknown or not resolved yet.
    #
    # @since 0.9.0
    # @api private
    def self.[](name)
      @_resolved.fetch(name) do
        raise ArgumentError.new("Component not resolved: `#{name}'.\nResolved components are: #{@_resolved.keys.join(', ')}")
      end
    end

    # Release all the resolved components.
    # This is used for code reloading.
    #
    # NOTE: this MUST NOT be used unless you know what you're doing.
    #
    # @example
    #   Hanami::Components.resolved('repository.users') { UserRepository.new }
    #   Hanami::Components['repository.users'] # => #<UserRepository relations=[...]>
    #
    #   Hanami::Components.release
    #   Hanami::Components['repository.users']
    #   # => ArgumentError: Component not resolved: `repo'.
    #   # => Resolved components are: ...
    #
    # @since 1.0.0
    # @api private
    def self.release
      @_resolved.clear
    end

    require 'hanami/components/component'
    require 'hanami/components/components'
  end
end
