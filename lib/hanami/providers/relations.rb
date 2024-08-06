# frozen_string_literal: true

module Hanami
  module Providers
    # @api private
    # @since 2.2.0
    class Relations < Hanami::Provider::Source
      def start
        start_and_import_parent_relations and return if slice.parent && slice.config.db.import_from_parent

        slice.start :db

        register_relations target["db.rom"]
      end

      private

      def register_relations(rom)
        rom.relations.each do |name, _|
          register name, rom.relations[name]
        end
      end

      def start_and_import_parent_relations
        slice.parent.start :relations

        register_relations slice.parent["db.rom"]
      end
    end
  end
end
