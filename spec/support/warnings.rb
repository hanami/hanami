# frozen_string_literal: true

# This file is synced from hanakai-rb/repo-sync

require "warning"

Warning[:experimental] = false if Warning.respond_to?(:[])

# Ignore all warnings in Gem dependencies
Gem.path.each do |path|
  Warning.ignore(//, path)
end
