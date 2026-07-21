# frozen_string_literal: true

module RSpec
  module Support
    module DatabaseUrl
      # Builds a database_url appropriate for the current Ruby engine. JRuby connects via JDBC,
      # so it requires a "jdbc:" URL rather than the native sqlite/postgres/mysql2 schemes.
      def sqlite_database_url(path = nil)
        if RUBY_ENGINE == "jruby"
          # The JDBC driver resolves relative paths against the JVM's own working directory,
          # which Ruby's Dir.chdir does not move, so give it an absolute path instead.
          path ? "jdbc:sqlite:#{File.expand_path(path)}" : "jdbc:sqlite::memory:"
        else
          path ? "sqlite://#{path}" : "sqlite::memory"
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::DatabaseUrl
end
