require 'test_helper'

describe 'rake tasks' do
  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('rake_test_app')
  end

  after do
    Dir.chdir @current_dir
    @current_dir = nil
  end

  it 'inherits environment and returns environment correctly' do
    output = `bundle exec rake inspect`.strip
    output.must_equal 'development'
  end
end
