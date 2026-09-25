# frozen_string_literal: true

module Hanami
  # @api private
  module Providers
    # Require the source files for all first-party provider sources, registering each as a `:hanami`
    # provider source (see Dry System's `.register_provider_source`).
    #
    # These are required with {Hanami::Slice} itself, before any slice is prepared. This allows for
    # {Hanami::Slice::ClassMethods#configure_provider} to be called from directly within a slice or
    # app class body, a requirement for single-file apps.
    require_relative "providers/logger"
    require_relative "providers/i18n" if Hanami.bundled?("i18n")
    require_relative "providers/db" if Hanami.bundled?("hanami-db")
    require_relative "providers/mailers" if Hanami.bundled?("hanami-mailer")
  end
end
