# frozen_string_literal: true

module RSpec
  module FeatureExampleGroup
    def self.included(group)
      group.metadata[:type] = :feature
      Capybara.app = Hanami.app
    end
  end
end
