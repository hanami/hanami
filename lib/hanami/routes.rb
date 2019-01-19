# frozen_string_literal: true

module Hanami
  # Hanami application routes
  #
  # @since 2.0.0
  class Routes
    attr_reader :apps

    def initialize(&blk)
      @blk = blk
      @apps = []
      instance_eval(&blk)
    end

    def to_proc
      @blk
    end

    def mount(app, **)
      @apps << app if app.is_a?(Symbol)
    end

    # rubocop:disable Style/MethodMissingSuper
    # rubocop:disable Style/MissingRespondToMissing
    def method_missing(*)
    end
    # rubocop:enable Style/MissingRespondToMissing
    # rubocop:enable Style/MethodMissingSuper
  end
end
