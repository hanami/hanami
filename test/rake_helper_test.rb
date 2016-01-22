require 'test_helper'
require 'hanami/rake_helper'

describe Hanami::RakeHelper do
  describe '.install_tasks' do
    before do
      Hanami::RakeHelper.install_tasks
    end

    let(:app) { Rake.application }

    it 'defines "preload"' do
      task = rake_task "preload"
      task.prerequisites.must_equal []
    end

    it 'defines "environment"' do
      task = rake_task "environment"
      task.prerequisites.must_equal ["preload"]
    end

    it 'defines "db:migrate"' do
      task = rake_task "db:migrate"
      task.prerequisites.must_equal []
    end

    it 'defines "assets:precompile"' do
      task = rake_task "assets:precompile"
      task.prerequisites.must_equal []
    end
  end

  private

  def rake_task(name)
    app.tasks.find do |task|
      task.name == name
    end
  end
end
