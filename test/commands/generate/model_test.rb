require 'test_helper'
require 'lotus/commands/generate/model'
require 'fileutils'

describe Lotus::Commands::Generate::Model do
  describe 'with invalid arguments' do
    it 'requires model name' do
      assert_exception_raised(ArgumentError, 'Model name nil or empty.') do
        Lotus::Commands::Generate::Model.new({}, nil)
      end

      assert_exception_raised(ArgumentError, 'Model name nil or empty.') do
        Lotus::Commands::Generate::Model.new({}, '')
      end

      assert_exception_raised(ArgumentError, 'Model name nil or empty.') do
        Lotus::Commands::Generate::Model.new({}, '   ')
      end
    end

    it 'validates model name' do
      assert_exception_raised(ArgumentError, "Invalid model name. The model name shouldn't begin with a number.") do
        Lotus::Commands::Generate::Model.new({}, 123)
      end
    end
  end

  describe 'sanitizes model name' do
    it 'downcases it' do
      with_temp_dir do |original_wd|
        command = Lotus::Commands::Generate::Model.new({}, 'CaR')
        capture_io { command.start }
        assert_generated_file(original_wd.join('test/fixtures/commands/generate/model/car.rb'), 'lib/testapp/entities/car.rb')
      end
    end

  end

  describe 'with valid arguments' do
    describe 'with rspec' do
      it 'creates model, repository and spec files' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::Generate::Model.new({'test' => 'rspec'}, 'car')
          capture_io { command.start }

          assert_generated_file(original_wd.join('test/fixtures/commands/generate/model/car_repository_spec.rspec.rb'), 'spec/testapp/repositories/car_repository_spec.rb')
          assert_generated_file(original_wd.join('test/fixtures/commands/generate/model/car_spec.rspec.rb'), 'spec/testapp/entities/car_spec.rb')
          assert_generated_file(original_wd.join('test/fixtures/commands/generate/model/car.rb'), 'lib/testapp/entities/car.rb')
          assert_generated_file(original_wd.join('test/fixtures/commands/generate/model/car_repository.rb'), 'lib/testapp/repositories/car_repository.rb')
        end
      end
    end

    describe 'with minitest' do
      it 'creates model, repository and spec files' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::Generate::Model.new({}, 'car')
          capture_io { command.start }

          assert_generated_file(original_wd.join('test/fixtures/commands/generate/model/car_repository_spec.minitest.rb'), 'spec/testapp/repositories/car_repository_spec.rb')
          assert_generated_file(original_wd.join('test/fixtures/commands/generate/model/car_spec.minitest.rb'), 'spec/testapp/entities/car_spec.rb')
          assert_generated_file(original_wd.join('test/fixtures/commands/generate/model/car.rb'), 'lib/testapp/entities/car.rb')
          assert_generated_file(original_wd.join('test/fixtures/commands/generate/model/car_repository.rb'), 'lib/testapp/repositories/car_repository.rb')
        end
      end
    end
  end

  describe '#destroy' do
    it 'destroys model, repository and spec files' do
      with_temp_dir do |original_wd|
        capture_io {
          Lotus::Commands::Generate::Model.new({}, 'car').start

          Lotus::Commands::Generate::Model.new({}, 'car').destroy.start
        }

        refute_file_exists('spec/testapp/repositories/car_repository_spec.rb')
        refute_file_exists('spec/testapp/entities/car_spec.rb')
        refute_file_exists('lib/testapp/entities/car.rb')
        refute_file_exists('lib/testapp/repositories/car_repository.rb')
      end
    end
  end

end
