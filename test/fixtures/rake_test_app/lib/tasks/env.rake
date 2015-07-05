task :environment do
  require 'lotus/environment'
  require Lotus::Environment.new.env_config
end