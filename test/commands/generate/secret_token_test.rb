require 'test_helper'
require 'hanami/commands/generate/secret_token'

describe Hanami::Commands::Generate::SecretToken do
  describe 'with no argument' do
    it 'prints a generated secret token' do
      command = Hanami::Commands::Generate::SecretToken.new(nil)
      out, err = capture_io { command.start }
      assert (out =~ /[a-f, 0-9]{64}/), "Expected '#{out}' to contain a generated secret token."
    end
  end

  describe 'with an application name' do
    it 'prints a ENV var with instructions' do
      command = Hanami::Commands::Generate::SecretToken.new('admin')
      out, err = capture_io { command.start }
      assert (out =~ /Set the following environment variable to provide the secret token:/ ), "Expected '#{out}' to provide instruction to set the secret token."
      assert (out =~ /ADMIN_SESSIONS_SECRET=\"[a-f, 0-9]{64}\"/), "Expected '#{out}' to contain a session secret property."
    end
  end
end
