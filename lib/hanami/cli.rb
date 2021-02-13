# frozen_string_literal: true

require "dry/cli"

module Hanami
  module CLI
    extend Dry::CLI::Registry

    require_relative "./cli/version"
  end
end
