# frozen_string_literal: true

RSpec.configure do |config|
  # Use the recommended non-monkey patched syntax.
  config.disable_monkey_patching!

  # Use and configure rspec-expectations.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Use and configure rspec-mocks.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on a
    # real object.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Limit a spec run to individual examples or groups you care about by tagging
  # them with `:focus` metadata. When nothing is tagged with `:focus`, all
  # examples get run.
  #
  # RSpec also provides aliases for `it`, `describe`, and `context` that include
  # `:focus` metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Allow RSpec to persist some state between runs in order to support the
  # `--only-failures` and `--next-failure` CLI options. We recommend you
  # configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Uncomment this to enable warnings. This is recommended, but in some cases
  # may be too noisy due to issues in dependencies.
  # config.warnings = true

  # Show more verbose output when running an individual spec file.
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  # Print the 10 slowest examples and example groups at the end of the spec run,
  # to help surface which specs are running particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run:
  #
  # --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # This allows you to use `--seed` to deterministically reproduce test failures
  # related to randomization by passing the same `--seed` value as the one that
  # triggered the failure.
  Kernel.srand config.seed
end
