require 'rake'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

namespace :test do
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task['spec'].invoke
  end
end

task default: :spec
