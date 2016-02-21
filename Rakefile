require 'rake'
require 'rake/testtask'
require 'bundler/gem_tasks'

Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
  t.libs.push 'test'
end

namespace :test do
  task :coverage do
    ENV['COVERAGE'] = 'true'
    ENV['TESTOPTS'] = '--seed=26843'
    Rake::Task['test'].invoke
  end
end

task default: :test

