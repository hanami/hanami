# frozen_string_literal: true

module RSpec
  module Support
    module Matchers
      module HTML
        def squish(str)
          str.gsub(/[[:space:]]+/, " ").strip
        end
      end
    end
  end
end

RSpec::Matchers.define :eq_html do |expected_html|
  include RSpec::Support::Matchers::HTML

  match do |actual_html|
    squish(actual_html) == squish(expected_html)
  end
end

RSpec::Matchers.define :include_html do |expected_html|
  include RSpec::Support::Matchers::HTML

  match do |actual_html|
    squish(actual_html).include?(squish(expected_html))
  end
end
