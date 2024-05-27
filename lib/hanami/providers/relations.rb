# frozen_string_literal: true

module Hanami
  module Providers
    # @api private
    # @since 2.2.0
    class Relations < Dry::System::Provider::Source
      def start
        start_and_import_parent_relations and return if target.parent && target.config.db.import_from_parent

        target.start :db

        register_relations target["db.rom"]
      end

      private

      def register_relations(rom)
        rom.relations.each do |name, _|
          register name, rom.relations[name]
        end
      end

      def start_and_import_parent_relations
        target.parent.start :relations

        register_relations target.parent["db.rom"]
      end
    end
  end
end
