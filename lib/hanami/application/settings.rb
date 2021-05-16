# frozen_string_literal: true

require "dry/configurable"

module Hanami
  class Application
    # Application settings
    #
    # @since 2.0.0
    module Settings
      def self.build(store, loader, &definition_block)
        # If we wanted to customise our wrapping of dry-configurable (e.g. to have our
        # `setting` methods offer slightly different params signatures, or to add any
        # other specialised behaviour) we could turn the `Settings` module here into a
        # class that includes Dry::Configurable and then subclass _it_ instead of just
        # making a new class without any defined superclass
        Class.new { include Dry::Configurable }
          .instance_eval(&definition_block)
          .new
          .config
          .then do |settings|
            loader.load(settings, store)
          end
      end
    end
  end
end
