# frozen_string_literal: true

module Hanami
  module Extensions
    module View
      # @api public
      # @since 2.1.0
      module Part
        # @api private
        # @since 2.1.0
        def self.included(part_class)
          super

          part_class.extend(Hanami::SliceConfigurable)
          part_class.extend(ClassMethods)
        end

        # @api private
        # @since 2.1.0
        module ClassMethods
          # @api private
          # @since 2.1.0
          def configure_for_slice(slice)
            extend SliceConfiguredPart.new(slice)

            const_set :PartHelpers, Class.new(PartHelpers) { |klass|
              klass.configure_for_slice(slice)
            }
          end
        end

        # Returns an object including the default Hanami helpers as well as the user-defined helpers
        # for the part's slice.
        #
        # Use this when you need to access helpers inside your part classes.
        #
        # @return [Object] the helpers object
        #
        # @api public
        # @since 2.1.0
        def helpers
          @helpers ||= self.class.const_get(:PartHelpers).new(context: _context)
        end
      end

      # Standalone helpers class including both {StandardHelpers} as well as the user-defined
      # helpers for the slice.
      #
      # Used used where helpers should be addressed via an intermediary object (i.e. in parts),
      # rather than mixed into a class directly.
      #
      # @api private
      # @since 2.1.0
      class PartHelpers
        extend Hanami::SliceConfigurable

        include StandardHelpers

        # @api private
        # @since 2.1.0
        def self.configure_for_slice(slice)
          extend SliceConfiguredHelpers.new(slice)
        end

        # Returns the context for the current view rendering.
        #
        # @return [Hanami::View::Context] the context
        #
        # @api public
        # @since 2.1.0
        attr_reader :_context

        # @api public
        # @since 2.1.0
        alias_method :context, :_context

        # @api private
        # @since 2.1.0
        def initialize(context:)
          @_context = context
        end
      end
    end
  end
end

Hanami::View::Part.include(Hanami::Extensions::View::Part)
