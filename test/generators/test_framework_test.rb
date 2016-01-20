require 'test_helper'
require 'hanami/generators/test_framework'

describe Hanami::Generators::TestFramework do

  describe 'respects hanamirc' do
    it 'detects rspec' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'hanamirc', 'with_rspec'), '.hanamirc'
        hanamirc = Hanami::Hanamirc.new(Pathname.new(Dir.pwd))
        test_framework = Hanami::Generators::TestFramework.new(hanamirc, nil)
        test_framework.rspec?.must_equal(true)
        test_framework.minitest?.must_equal(false)
      end
    end
    it 'detects minitest' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'hanamirc', 'with_minitest'), '.hanamirc'
        hanamirc = Hanami::Hanamirc.new(Pathname.new(Dir.pwd))
        test_framework = Hanami::Generators::TestFramework.new(hanamirc, nil)
        test_framework.rspec?.must_equal(false)
        test_framework.minitest?.must_equal(true)
      end
    end
  end

  describe 'override hanamirc with argument' do
    it 'detects rspec' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'hanamirc', 'with_minitest'), '.hanamirc'
        hanamirc = Hanami::Hanamirc.new(Pathname.new(Dir.pwd))
        test_framework = Hanami::Generators::TestFramework.new(hanamirc, 'rspec')
        test_framework.rspec?.must_equal(true)
        test_framework.minitest?.must_equal(false)
      end
    end
    it 'detects minitest' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'hanamirc', 'with_rspec'), '.hanamirc'
        hanamirc = Hanami::Hanamirc.new(Pathname.new(Dir.pwd))
        test_framework = Hanami::Generators::TestFramework.new(hanamirc, 'minitest')
        test_framework.rspec?.must_equal(false)
        test_framework.minitest?.must_equal(true)
      end
    end
  end

end
