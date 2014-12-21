require 'lotusrb'

Bundler.require(
  *Lotus::Environment.new.bundler_groups
)
