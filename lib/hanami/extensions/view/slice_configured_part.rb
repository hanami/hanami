# frozen_string_literal: true

module Hanami
  module Extensions
    module View
      # Provides slice-specific configuration and behavior for any view part class defined within a
      # slice's module namespace.
      #
      # @api public
      # @since 2.1.0
      class SliceConfiguredPart < Module
        attr_reader :slice

        # @api private
        # @since 2.1.0
        def initialize(slice)
          super()
          @slice = slice
        end

        # @api private
        # @since 2.1.0
        def extended(klass)
          define_new
        end

        # @return [String]
        #
        # @api public
        # @since 2.1.0
        def inspect
          "#<#{self.class.name}[#{slice.name}]>"
        end

        private

        # Defines a `.new` method on the part class that provides a default `rendering:` argument of
        # a rendering coming from a view configured for the slice. This means that any part can be
        # initialized standalone (with a `value:` only) and still have access to all the integrated
        # view facilities from the slice, such as helpers. This is helpful when unit testing parts.
        #
        # @example
        #   module MyApp::Views::Parts
        #     class Post < MyApp::View::Part
        #       def title_tag
        #         helpers.h1(value.title)
        #       end
        #     end
        #   end
        #
        #   # Useful when unit testing parts
        #   part = MyApp::Views::Parts::Post.new(value: hello_world_post)
        #   part.title_tag # => "<h1>Hello world</h1>"
        def define_new
          slice = self.slice

          define_method(:new) do |**args|
            return super(**args) if args.key?(:rendering)

            slice_rendering = Class.new(Hanami::View)
              .configure_for_slice(slice)
              .new
              .rendering

            super(rendering: slice_rendering, **args)
          end
        end
      end
    end
  end
end
