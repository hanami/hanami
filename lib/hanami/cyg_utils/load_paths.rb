# frozen_string_literal: true

require "hanami/cyg_utils/kernel"

module Hanami
  module CygUtils
    # A collection of loading paths.
    #
    # @since 0.2.0
    class LoadPaths
      # Initialize a new collection for the given paths
      #
      # @param paths [String, Pathname, Array<String>, Array<Pathname>] A single
      #   or a collection of objects that can be converted into a Pathname
      #
      # @return [Hanami::CygUtils::LoadPaths] self
      #
      # @since 0.2.0
      #
      # @see http://ruby-doc.org/stdlib/libdoc/pathname/rdoc/Pathname.html
      # @see Hanami::CygUtils::Kernel.Pathname
      def initialize(*paths)
        @paths = CygUtils::Kernel.Array(paths)
      end

      # It specifies the policy for initialize copies of the object, when #clone
      # or #dup are invoked.
      #
      # @api private
      # @since 0.2.0
      #
      # @see http://ruby-doc.org/core/Object.html#method-i-clone
      # @see http://ruby-doc.org/core/Object.html#method-i-dup
      #
      # @example
      #   require 'hanami/cyg_utils/load_paths'
      #
      #   paths  = Hanami::CygUtils::LoadPaths.new '.'
      #   paths2 = paths.dup
      #
      #   paths  << '..'
      #   paths2 << '../..'
      #
      #   paths
      #     # => #<Hanami::CygUtils::LoadPaths:0x007f84e0cad430 @paths=[".", ".."]>
      #
      #   paths2
      #     # => #<Hanami::CygUtils::LoadPaths:0x007faedc4ad3e0 @paths=[".", "../.."]>
      def initialize_copy(original)
        @paths = original.instance_variable_get(:@paths).dup
      end

      # Iterates through the collection and yields the given block.
      # It skips duplications and raises an error in case one of the paths
      # doesn't exist.
      #
      # @yield [pathname] the block of code that acts on the collection
      # @yieldparam pathname [Pathname]
      #
      # @return [void]
      #
      # @raise [Errno::ENOENT] if one of the paths doesn't exist
      #
      # @since 0.2.0
      def each
        @paths.each do |path|
          yield realpath(path)
        end
      end

      # Adds the given path(s).
      #
      # It returns self, so that multiple operations can be performed.
      #
      # @param paths [String, Pathname, Array<String>, Array<Pathname>] A single
      #   or a collection of objects that can be converted into a Pathname
      #
      # @return [Hanami::CygUtils::LoadPaths] self
      #
      # @raise [RuntimeError] if the object was previously frozen
      #
      # @since 0.2.0
      #
      # @see http://ruby-doc.org/stdlib/libdoc/pathname/rdoc/Pathname.html
      # @see Hanami::CygUtils::Kernel.Pathname
      # @see Hanami::CygUtils::LoadPaths#freeze
      #
      # @example Basic usage
      #   require 'hanami/cyg_utils/load_paths'
      #
      #   paths = Hanami::CygUtils::LoadPaths.new
      #   paths.push '.'
      #   paths.push '..', '../..'
      #
      # @example Chainable calls
      #   require 'hanami/cyg_utils/load_paths'
      #
      #   paths = Hanami::CygUtils::LoadPaths.new
      #   paths.push('.')
      #        .push('..', '../..')
      #
      # @example Shovel alias (#<<)
      #   require 'hanami/cyg_utils/load_paths'
      #
      #   paths = Hanami::CygUtils::LoadPaths.new
      #   paths << '.'
      #   paths << ['..', '../..']
      #
      # @example Chainable calls with shovel alias (#<<)
      #   require 'hanami/cyg_utils/load_paths'
      #
      #   paths = Hanami::CygUtils::LoadPaths.new
      #   paths << '.' << '../..'
      def push(*paths)
        @paths.push(*paths)
        @paths = Kernel.Array(@paths)
        self
      end

      alias_method :<<, :push

      # It freezes the object by preventing further modifications.
      #
      # @since 0.2.0
      #
      # @see http://ruby-doc.org/core/Object.html#method-i-freeze
      #
      # @example
      #   require 'hanami/cyg_utils/load_paths'
      #
      #   paths = Hanami::CygUtils::LoadPaths.new
      #   paths.freeze
      #
      #   paths.frozen?  # => true
      #
      #   paths.push '.' # => RuntimeError
      def freeze
        super
        @paths.freeze
      end

      # @since 0.6.0
      # @api private
      def ==(other)
        case other
        when self.class
          other.paths == paths
        else
          other == paths
        end
      end

      protected

      # @since 0.6.0
      # @api private
      attr_reader :paths

      private

      # Allows subclasses to define their own policy to discover the realpath
      # of the given path.
      #
      # @since 0.2.0
      # @api private
      def realpath(path)
        CygUtils::Kernel.Pathname(path).realpath
      end
    end
  end
end
