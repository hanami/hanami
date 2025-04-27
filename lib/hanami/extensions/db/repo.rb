# frozen_string_literal: true

require "hanami/db"

module Hanami
  module Extensions
    # @api private
    # @since 2.2.0
    module DB
      # @api private
      # @since 2.2.0
      module Repo
        def self.included(repo_class)
          super

          repo_class.extend(Hanami::SliceConfigurable)
          repo_class.extend(ClassMethods)
        end

        # @api private
        # @since 2.2.0
        module ClassMethods
          def configure_for_slice(slice)
            extend SliceConfiguredRepo.new(slice)
          end
        end
      end

      # @api private
      # @since 2.2.0
      class SliceConfiguredRepo < Module
        attr_reader :slice

        def initialize(slice)
          super()
          @slice = slice
        end

        def extended(repo_class)
          define_inherited
          configure_repo(repo_class)
          define_new
        end

        def inspect
          "#<#{self.class.name}[#{slice.name}]>"
        end

        private

        def define_inherited
          root_for_repo_class = method(:root_for_repo_class)

          define_method(:inherited) do |subclass|
            super(subclass)

            unless subclass.root
              root = root_for_repo_class.(subclass)
              subclass.root root if root
            end
          end
        end

        def configure_repo(repo_class)
          repo_class.struct_namespace struct_namespace
        end

        def define_new
          resolve_rom = method(:resolve_rom)

          define_method(:new) do |**kwargs|
            super(container: kwargs.fetch(:container) { resolve_rom.() })
          end
        end

        def resolve_rom
          slice["db.rom"]
        end

        def root_for_repo_class(repo_class)
          repo_class_name = slice.inflector.demodulize(repo_class)
                                 .then { slice.inflector.underscore(_1) }
    
          return if repo_class_name.match?(/^(repo|repository)$/)
          return unless repo_class_name.match?(/(repo|repository)$/)
    
          repo_class_name.gsub(/_(repo|repository)$/, "")
                         .then { slice.inflector.pluralize(_1) }
                         .then(&:to_sym)
        end

        def struct_namespace
          @struct_namespace ||=
            if slice.namespace.const_defined?(:Structs)
              slice.namespace.const_get(:Structs)
            else
              slice.namespace.const_set(:Structs, Module.new)
            end
        end
      end
    end
  end
end

Hanami::DB::Repo.include(Hanami::Extensions::DB::Repo)
