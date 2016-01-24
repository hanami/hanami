require 'test_helper'
require 'hanami/generators/console_engine'

describe Hanami::Generators::ConsoleEngine do

  describe 'respects hanamirc' do
    it 'detects irb' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'hanamirc', 'with_irb'), '.hanamirc'
        hanamirc = Hanami::Hanamirc.new(Pathname.new(Dir.pwd))
        test_framework = Hanami::Generators::ConsoleEngine.new(hanamirc, nil)
        test_framework.irb?.must_equal(true)
        test_framework.pry?.must_equal(false)
        test_framework.ripl?.must_equal(false)
      end
    end

    it 'detects pry' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'hanamirc', 'with_pry'), '.hanamirc'
        hanamirc = Hanami::Hanamirc.new(Pathname.new(Dir.pwd))
        test_framework = Hanami::Generators::ConsoleEngine.new(hanamirc, nil)
        test_framework.irb?.must_equal(false)
        test_framework.pry?.must_equal(true)
        test_framework.ripl?.must_equal(false)
      end
    end

    it 'detects ripl' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'hanamirc', 'with_ripl'), '.hanamirc'
        hanamirc = Hanami::Hanamirc.new(Pathname.new(Dir.pwd))
        test_framework = Hanami::Generators::ConsoleEngine.new(hanamirc, nil)
        test_framework.irb?.must_equal(false)
        test_framework.pry?.must_equal(false)
        test_framework.ripl?.must_equal(true)
      end
    end
  end

  describe 'override hanamirc with argument' do
    it 'detects irb' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'hanamirc', 'with_irb'), '.hanamirc'
        hanamirc = Hanami::Hanamirc.new(Pathname.new(Dir.pwd))
        test_framework = Hanami::Generators::ConsoleEngine.new(hanamirc, 'pry')
        test_framework.irb?.must_equal(false)
        test_framework.pry?.must_equal(true)
        test_framework.ripl?.must_equal(false)
      end
    end

    it 'detects pry' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'hanamirc', 'with_pry'), '.hanamirc'
        hanamirc = Hanami::Hanamirc.new(Pathname.new(Dir.pwd))
        test_framework = Hanami::Generators::ConsoleEngine.new(hanamirc, 'irb')
        test_framework.irb?.must_equal(true)
        test_framework.pry?.must_equal(false)
        test_framework.ripl?.must_equal(false)
      end
    end

    it 'detects ripl' do
      with_temp_dir do |original_wd|
        FileUtils.cp original_wd.join('test', 'fixtures', 'hanamirc', 'with_ripl'), '.hanamirc'
        hanamirc = Hanami::Hanamirc.new(Pathname.new(Dir.pwd))
        test_framework = Hanami::Generators::ConsoleEngine.new(hanamirc, 'irb')
        test_framework.irb?.must_equal(true)
        test_framework.pry?.must_equal(false)
        test_framework.ripl?.must_equal(false)
      end
    end
  end

end
