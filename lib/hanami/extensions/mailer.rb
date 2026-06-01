# frozen_string_literal: true

require "hanami/mailer"
require_relative "mailer/slice_configured_mailer"

module Hanami
  module Extensions
    # Integrated behavior for `Hanami::Mailer` classes within Hanami apps.
    #
    # @api private
    module Mailer
      def self.included(mailer_class)
        super

        mailer_class.extend(Hanami::SliceConfigurable)
        mailer_class.extend(ClassMethods)
      end

      module ClassMethods
        def configure_for_slice(slice)
          extend SliceConfiguredMailer.new(slice)
        end
      end
    end
  end
end

Hanami::Mailer.include(Hanami::Extensions::Mailer)
