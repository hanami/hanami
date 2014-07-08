require 'lotus/router'
require 'lotus/controller'
require 'lotus/view'

module Lotus
  module Frameworks
    module Action
      module Rack
        protected
        def response
          super + [self]
        end
      end
    end
  end
end

Lotus::Action::Rack.class_eval do
  def self.included(base)
    base.include Lotus::Frameworks::Action::Rack
  end
end

Lotus::Action.class_eval do
  def to_rendering
    exposures.merge(format: format)
  end
end
