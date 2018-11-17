# frozen_string_literal: true

module Hanami
  # Hanami private IoC
  #
  # @since 2.0.0
  class Container
    def self.finalize!
      root = Hanami.root
      $LOAD_PATH.unshift root.join("lib")

      require root.join("config", "environment").to_s
      Hanami::Utils.require!(root.join("apps", "**", "*.rb"))
      require root.join("config", "routes").to_s
    end
  end
end
