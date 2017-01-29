require 'hanami/model'
require 'hanami/mailer'
Dir["#{ __dir__ }/rake_tasks/**/*.rb"].each { |file| require_relative file }
ADAPTER_TYPE = if Hanami::Utils.jruby?
                 require 'jdbc/sqlite3'
                 Jdbc::SQLite3.load_driver

                 'jdbc:sqlite'
               else
                 require 'sqlite3'

                 'sqlite'
               end
Hanami::Model.configure do
  ##
  # Database adapter
  #
  # Available options:
  #
  #  * Memory adapter
  #    adapter type: :memory, uri: 'memory://localhost/rake_tasks_development'
  #
  #  * SQL adapter
  #    adapter type: :sql, uri: 'sqlite://db/rake_tasks_development.sqlite3'
  #    adapter type: :sql, uri: 'postgresql://localhost/rake_tasks_development'
  #    adapter type: :sql, uri: 'mysql://localhost/rake_tasks_development'
  #
  adapter type: :sql, uri: "#{ADAPTER_TYPE}://#{Dir.pwd}/db/rake_tasks_test.sqlite"

  ##
  # Migrations
  #
  migrations 'db/migrations'
  schema     'db/schema.sql'

  ##
  # Database mapping
  #
  # Intended for specifying application wide mappings.
  #
  mapping do
     collection :users do
       entity     User
       repository UserRepository

       attribute :id,   Integer
       attribute :name, String
     end
  end
end.load!

Hanami::Mailer.configure do
  root "#{ __dir__ }/rake_tasks/mailers"

  # See http://hanamirb.org/guides/mailers/delivery
  delivery do
    development :test
    test        :test
    # production :smtp, address: ENV['SMTP_PORT'], port: 1025
  end
end.load!
