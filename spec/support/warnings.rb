# frozen_string_literal: true

# This file is synced from hanakai-rb/repo-sync

require "warning"

# Ignore warnings for experimental features
Warning[:experimental] = false if Warning.respond_to?(:[])

# Ignore all warnings coming from gem dependencies
Gem.path.each do |path|
  Warning.ignore(//, path)
end
