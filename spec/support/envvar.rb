# frozen_string_literal: true

def with_envvars(vars_for_test, &block)
  original_envvars = ENV.to_h
  ENV.replace(original_envvars.merge(vars_for_test))

  block.call

  ENV.replace(original_envvars)
end
