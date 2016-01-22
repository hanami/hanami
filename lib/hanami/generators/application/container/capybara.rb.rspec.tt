module RSpec
  module FeatureExampleGroup
    def self.included(group)
      group.metadata[:type] = :feature
      Capybara.app = Hanami::Container.new
    end
  end
end
