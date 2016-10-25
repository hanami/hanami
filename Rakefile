require 'rake'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

namespace :spec do
  RSpec::Core::RakeTask.new(:unit) do |task|
    file_list = FileList['spec/**/*_spec.rb']
    file_list = file_list.exclude("spec/{integration,isolation}/**/*_spec.rb")

    task.pattern = file_list
  end

  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task['spec:unit'].invoke
  end
end

task default: 'spec:unit'
