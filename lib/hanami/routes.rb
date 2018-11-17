# frozen_string_literal: true

module Hanami
  # Hanami application routes
  #
  # @since 2.0.0
  class Routes
    def initialize(&blk)
      @blk = blk
    end

    def to_proc
      @blk
    end
  end
end
