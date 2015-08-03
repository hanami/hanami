require 'test_helper'
require 'lotus/commands/generate/model'
require 'fileutils'

describe Lotus::Commands::Generate::Model do
  describe 'with invalid arguments' do
    it 'requires model name' do
      -> { Lotus::Commands::Generate::Model.new({}, nil) }.must_raise ArgumentError
      -> { Lotus::Commands::Generate::Model.new({}, '') }.must_raise ArgumentError
      -> { Lotus::Commands::Generate::Model.new({}, '   ') }.must_raise ArgumentError
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
end
