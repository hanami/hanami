# frozen_string_literal: true

# This file is synced from hanakai-rb/repo-sync

RSpec.configure do |config|
  # When no filter given, search and run focused tests
  config.filter_run_when_matching :focus

  # Disables rspec monkey patches (no reason for their existence tbh)
  config.disable_monkey_patching!

  # Run ruby in verbose mode
  config.warnings = true

  # Collect all failing expectations automatically,
  # without calling aggregate_failures everywhere
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  if ENV['CI']
    # No focused specs should be committed. This ensures
    # builds fail when this happens.
    config.before(:each, :focus) do
      raise StandardError, "You've committed a focused spec!"
    end
  end
end
