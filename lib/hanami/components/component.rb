module Hanami
  # @since 0.9.0
  # @api private
  module Components
    # Base component
    #
    # @since 0.9.0
    # @api private
    #
    # @see Hanami::Components
    class Component
      # Instantiate a new component
      #
      # @param name [String] the component name
      # @param blk [Proc] the logic of the component
      #
      # @return [Hanami::Components::Component]
      #
      # @since 0.9.0
      # @api private
      def initialize(name, &blk)
        @name         = name
        @requirements = []
        @_prepare     = ->(*) {}
        @_resolve     = -> {}
        instance_eval(&blk)
      end

      # Run or resolve the component
      #
      # @param configuration [Hanami::Configuration] the Hanami configuration for the project
      #
      # @since 0.9.0
      # @api private
      def call(configuration)
        resolve_requirements
        _prepare.call(configuration)

        unless _run.nil?
          _run.call(configuration)
          return
        end

        resolved(name, _resolve.call(configuration))
      end

      private

      # @since 1.3.0
      # @api private
      #
      # @see Hanami::Component#logger_interface?
      LOGGER_METHODS = %i[info warn debug]

      # Component name
      #
      # @return [String]
      #
      # @since 0.9.0
      # @api private
      attr_reader :name

      # Component requirements
      #
      # @return [Array<String>]
      #
      # @since 0.9.0
      # @api private
      attr_reader :requirements

      # Prepare logic
      #
      # @since 0.9.0
      # @api private
      attr_accessor :_prepare

      # Resolve logic
      #
      # @since 0.9.0
      # @api private
      attr_accessor :_resolve

      # Run logic
      #
      # @since 0.9.0
      # @api private
      attr_accessor :_run

      # Declare component requirement(s)
      #
      # @param components [Array<String>] the name of the other components to
      #   depend on
      def requires(*components)
        self.requirements = Array(components).flatten
      end

      # Declare prepare logic
      #
      # @param blk [Proc] prepare logic
      #
      # @since 0.9.0
      # @api private
      def prepare(&blk)
        self._prepare = blk
      end

      # Declare resolve logic
      #
      # @param blk [Proc] resolve logic
      #
      # @since 0.9.0
      # @api private
      def resolve(&blk)
        self._resolve = blk
      end

      # Declare run logic
      #
      # @param blk [Proc] run logic
      #
      # @since 0.9.0
      # @api private
      def run(&blk)
        self._run = blk
      end

      # Set requirements
      #
      # @param names [Array<String>] the requirements
      #
      # @since 0.9.0
      # @api private
      def requirements=(names)
        @requirements = Array(names).flatten
      end

      # Resolve the requirements before to execute the logic of this component
      #
      # @since 0.9.0
      # @api private
      #
      # @see Hanami::Components.resolve
      def resolve_requirements
        Components.resolve(requirements)
      end

      # Get a registered component by name
      #
      # @param name [String] the component name
      #
      # @since 0.9.0
      # @api private
      #
      # @see Hanami::Components.component
      def component(name)
        Components.component(name)
      end

      # Mark a component as resolved by providing a value or a block.
      #
      # @param name [String] the name of the component to mark as resolved
      # @param value [Object] the optional value of the component
      # @param blk [Proc] the optional block which returning value is associated with the component.
      #
      # @since 0.9.0
      # @api private
      #
      # @see Hanami::Components.resolved
      def resolved(name, value = nil, &blk)
        Components.resolved(name, value, &blk)
      end

      # Check that instance has logger interfaces (#info, #warn and #debug)
      #
      # @since 1.3.0
      # @api private
      def logger_interface?(instance)
        LOGGER_METHODS.all? { |method| instance.respond_to?(method) }
      end
    end
  end
end
