# frozen_string_literal: true

require_relative "slice_behavior"

module Hanami
  # Distinct area of concern within an Hanami application
  #
  # @since 2.0.0
  class Slice
    def self.inherited(subclass)
      super

      subclass.instance_eval do
        # Initialize any variables that may be accessed inside slice class bodies
        @application = Hanami.application
      end

      subclass.extend(SliceBehavior)
    end
  end
end
