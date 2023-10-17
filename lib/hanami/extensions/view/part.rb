# frozen_string_literal: true

module Hanami
  module Extensions
    module View
      # @api private
      # @since 2.1.0
      module Part
        def self.included(part_class)
          super

          part_class.extend(Hanami::SliceConfigurable)
          part_class.extend(ClassMethods)
        end

        module ClassMethods
          def configure_for_slice(slice)
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
        # @return PartHelpers
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

        def self.configure_for_slice(slice)
          extend SliceConfiguredHelpers.new(slice)
        end

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
