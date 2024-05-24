# frozen_string_literal: true

module Hanami
  module Providers
    # @api private
    # @since 2.2.0
    class Relations < Dry::System::Provider::Source
      def start
        target.start(:db)

        rom = target["db.rom"]
        rom.relations.each do |name, _|
          register(name) { rom.relations[name] }
        end
      end
    end
  end
end
