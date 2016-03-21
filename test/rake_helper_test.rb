require 'test_helper'
require 'hanami/rake_helper'

describe Hanami::RakeHelper do
  before do
    Hanami::RakeHelper.install_tasks
  end

  let(:app) { Rake.application }

  describe '.install_tasks' do
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

  describe 'when "db:migrate" task failed' do
    it 'exits with failed status code' do
      task = rake_task "db:migrate"
      -> { task.invoke }.must_raise SystemExit
    end
  end

  describe 'when "assets:precompile" task failed' do
    it 'exits with failed status code' do
      task = rake_task "assets:precompile"
      -> { task.invoke }.must_raise SystemExit
    end
  end

  private

  def rake_task(name)
    app.tasks.find do |task|
      task.name == name
    end
  end

  module Hanami
    class RakeHelper
      def system(*args)
        nil
      end
    end
  end
end
