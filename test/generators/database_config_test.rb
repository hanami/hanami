require 'test_helper'
require 'hanami/generators/database_config'

describe Hanami::Generators::DatabaseConfig do
  let(:database_config) { Hanami::Generators::DatabaseConfig.new(engine, 'basecamp') }

  describe '#type' do
    describe 'when engine is SQL Database' do
      let(:engine) { 'sqlite' }

      it 'returns `:sql` symbol' do
        database_config.type.must_equal :sql
      end
    end

    describe 'when engine is filesystem' do
      let(:engine) { 'filesystem' }

      it 'returns `:file_system` symbol' do
        database_config.type.must_equal :file_system
      end

      it 'returns true' do
        database_config.filesystem?.must_equal true
      end
    end

    describe 'when engine is memory' do
      let(:engine) { 'memory' }

      it 'returns `:file_system` symbol' do
        database_config.type.must_equal :memory
      end
    end
  end

  describe '#sql?' do
    describe 'when engine is SQL Database' do
      %w(sqlite sqlite3 postgresql postgres mysql mysql2).each do |e|
        let(:engine) { e }

        it 'returns true' do
          database_config.sql?.must_equal true
        end
      end
    end

    describe 'when engine is non-SQL' do
      %w(file_system memory).each do |e|
        let(:engine) { e }

        it 'returns false' do
          database_config.sql?.must_equal false
        end
      end
    end
  end

  describe '#to_hash' do
    let(:adapter_prefix) { :'jdbc:' if Hanami::Utils.jruby? }

    describe 'SQL databases' do
      let(:engine) { 'postgres' }

      it 'returns a hash containing gem, right connection URIs and type' do
        database_config.to_hash.must_equal(
          gem: (Hanami::Utils.jruby? ? 'jdbc-postgres' : 'pg'),
          type: :sql,
          uri: {
            development: "#{ adapter_prefix }postgres://localhost/basecamp_development",
            test: "#{ adapter_prefix }postgres://localhost/basecamp_test"
          }
        )
      end
    end

    describe 'non-SQL databases' do
      let(:engine) { 'filesystem' }

      it 'returns a hash containing gem, right connection URIs and type' do
        database_config.to_hash.must_equal(
          gem: nil,
          type: :file_system,
          uri: {
            development: "file:///db/basecamp_development",
            test: "file:///db/basecamp_test"
          }
        )
      end
    end
  end
end
