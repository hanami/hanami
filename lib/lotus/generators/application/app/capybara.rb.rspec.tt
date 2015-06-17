module RSpec
  module FeatureExampleGroup
    def self.included(group)
      group.metadata[:type] = :feature
      Capybara.app = Lotus::Container.new
    end
  end
end
