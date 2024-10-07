# frozen_string_literal: true

if Hanami.bundled?("hanami-db")
  require "dry/operation"
  require "dry/operation/extensions/rom"

  Dry::Operation.include(Dry::Operation::Extensions::ROM)
end
