require 'test_helper'
require 'lotus/commands/generate/mailer'
require 'fileutils'

describe Lotus::Commands::Generate::Mailer do
  describe 'with invalid arguments' do
    it 'requires mailer name' do
      -> { Lotus::Commands::Generate::Mailer.new({}, nil) }.must_raise ArgumentError
      -> { Lotus::Commands::Generate::Mailer.new({}, '') }.must_raise ArgumentError
      -> { Lotus::Commands::Generate::Mailer.new({}, '   ') }.must_raise ArgumentError
    end
  end

  describe 'with valid arguments' do
    it 'underscores the mailer name' do
      with_temp_dir do |original_wd|
        command = Lotus::Commands::Generate::Mailer.new({}, 'ForgotPassword')
        capture_io { command.start }

        assert_generated_file(original_wd.join('test/fixtures/commands/generate/mailer/forgot_password.rb'), 'lib/testapp/mailers/forgot_password.rb')
      end
    end

    it 'uses --from option as the email sender' do
      with_temp_dir do |original_wd|
        command = Lotus::Commands::Generate::Mailer.new({from: "'support@bookshelf.com'"}, 'ForgotPassword')
        capture_io { command.start }

        assert_file_includes('lib/testapp/mailers/forgot_password.rb', /from\s+'support@bookshelf.com'/)
      end
    end

    it 'uses --to option as the email sendee' do
      with_temp_dir do |original_wd|
        command = Lotus::Commands::Generate::Mailer.new({to: "'log@bookshelf.com'"}, 'ForgotPassword')
        capture_io { command.start }

        assert_file_includes('lib/testapp/mailers/forgot_password.rb', /to\s+'log@bookshelf.com'/)
      end
    end

    it 'uses --subject option as the email subject' do
      with_temp_dir do |original_wd|
        command = Lotus::Commands::Generate::Mailer.new({subject: "'New Password'"}, 'ForgotPassword')
        capture_io { command.start }

        assert_file_includes('lib/testapp/mailers/forgot_password.rb', /subject\s+'New Password'/)
      end
    end

    it 'uses default options' do
      with_temp_dir do |original_wd|
        command = Lotus::Commands::Generate::Mailer.new({}, 'ForgotPassword')
        capture_io { command.start }

        assert_generated_file(original_wd.join('test/fixtures/commands/generate/mailer/forgot_password.rb'), 'lib/testapp/mailers/forgot_password.rb')
      end
    end

    describe 'with rspec' do
      it 'creates mailer and spec files' do
        skip('only one type of test framework is available')

        with_temp_dir do |original_wd|
          command = Lotus::Commands::Generate::Mailer.new({test: 'rspec'}, 'ForgotPassword')
          capture_io { command.start }

          assert_generated_mailer_and_spec('rspec', original_wd)
        end
      end
    end

    describe 'with minitest (default)' do
      it 'creates mailer and spec files' do
        with_temp_dir do |original_wd|
          command = Lotus::Commands::Generate::Mailer.new({}, 'ForgotPassword')
          capture_io { command.start }

          assert_generated_mailer_and_spec('minitest', original_wd)
        end
      end
    end
  end

  describe '#destroy' do
    it 'destroys mailer and spec files' do
      with_temp_dir do |original_wd|
        capture_io {
          Lotus::Commands::Generate::Mailer.new({}, 'ForgotPassword').start

          Lotus::Commands::Generate::Mailer.new({}, 'ForgotPassword').destroy.start
        }

        refute_file_exists('lib/testapp/mailers/forgot_password.rb')
        refute_file_exists('lib/testapp/mailers/templates/forgot_password.txt.erb')
        refute_file_exists('lib/testapp/mailers/templates/forgot_password.html.erb')
        refute_file_exists('spec/testapp/mailers/forgot_password_spec.rb')
      end
    end
  end

  def assert_generated_mailer_and_spec(test, original_wd)
    assert_generated_file(original_wd.join('test/fixtures/commands/generate/mailer/forgot_password.rb'), 'lib/testapp/mailers/forgot_password.rb')
    assert_generated_file(original_wd.join('test/fixtures/commands/generate/mailer/forgot_password.txt.erb'), 'lib/testapp/mailers/templates/forgot_password.txt.erb')
    assert_generated_file(original_wd.join('test/fixtures/commands/generate/mailer/forgot_password.html.erb'), 'lib/testapp/mailers/templates/forgot_password.html.erb')
    assert_generated_file(original_wd.join("test/fixtures/commands/generate/mailer/forgot_password_spec.#{test}.rb"), 'spec/testapp/mailers/forgot_password_spec.rb')
  end
end
