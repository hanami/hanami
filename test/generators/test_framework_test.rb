require 'test_helper'
require 'lotus/generators/test_framework'

describe Lotus::Generators::TestFramework do

  describe 'respects lotusrc' do
    it 'detects rspec' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'lotusrc', 'with_rspec'), '.lotusrc'
        lotusrc = Lotus::Lotusrc.new(Pathname.new(Dir.pwd))
        test_framework = Lotus::Generators::TestFramework.new(lotusrc, nil)
        test_framework.rspec?.must_equal(true)
        test_framework.minitest?.must_equal(false)
      end
    end
    it 'detects minitest' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'lotusrc', 'with_minitest'), '.lotusrc'
        lotusrc = Lotus::Lotusrc.new(Pathname.new(Dir.pwd))
        test_framework = Lotus::Generators::TestFramework.new(lotusrc, nil)
        test_framework.rspec?.must_equal(false)
        test_framework.minitest?.must_equal(true)
      end
    end
  end

  describe 'override lotusrc with argument' do
    it 'detects rspec' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'lotusrc', 'with_minitest'), '.lotusrc'
        lotusrc = Lotus::Lotusrc.new(Pathname.new(Dir.pwd))
        test_framework = Lotus::Generators::TestFramework.new(lotusrc, 'rspec')
        test_framework.rspec?.must_equal(true)
        test_framework.minitest?.must_equal(false)
      end
    end
    it 'detects minitest' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'lotusrc', 'with_rspec'), '.lotusrc'
        lotusrc = Lotus::Lotusrc.new(Pathname.new(Dir.pwd))
        test_framework = Lotus::Generators::TestFramework.new(lotusrc, 'minitest')
        test_framework.rspec?.must_equal(false)
        test_framework.minitest?.must_equal(true)
      end
    end
  end

end
