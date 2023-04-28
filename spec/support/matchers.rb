# frozen_string_literal: true

module RSpec
  module Support
    module Matchers
      module HTML
        def squish_html(str)
          str
            .gsub(/^[[:space:]]+/, "")
            .gsub(/>[[:space:]]+</m, "><")
            .strip
        end
      end
    end
  end
end

RSpec::Matchers.define :eq_html do |expected_html|
  include RSpec::Support::Matchers::HTML

  match do |actual_html|
    squish_html(actual_html) == squish_html(expected_html)
  end
end

RSpec::Matchers.define :include_html do |expected_html|
  include RSpec::Support::Matchers::HTML

  match do |actual_html|
    squish_html(actual_html).include?(squish_html(expected_html))
  end
end
