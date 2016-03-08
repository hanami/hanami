require 'hanami/model'
require 'hanami/mailer'
Dir["#{ __dir__ }/new_app/**/*.rb"].each { |file| require_relative file }

Hanami::Model.configure do
  # Database adapter
  #
  # Available options:
  #
  #  * File System adapter
  #    adapter type: :file_system, uri: 'file:///db/bookshelf_development'
  #
  #  * Memory adapter
  #    adapter type: :memory, uri: 'memory://localhost/new_app_development'
  #
  #  * SQL adapter
  #    adapter type: :sql, uri: 'sqlite://db/new_app_development.sqlite3'
  #    adapter type: :sql, uri: 'postgres://localhost/new_app_development'
  #    adapter type: :sql, uri: 'mysql://localhost/new_app_development'
  #
  adapter type: :file_system, uri: ENV['DATABASE_URL']

  ##
  # Database mapping
  #
  # Intended for specifying application wide mappings.
  #
  mapping do
    # collection :users do
    #   entity     User
    #   repository UserRepository
    #
    #   attribute :id,   Integer
    #   attribute :name, String
    # end
  end
end.load!

Hanami::Mailer.configure do
  root "#{ __dir__ }/new_app/mailers"

  # See http://hanamirb.org/guides/mailers/delivery
  delivery do
    development :test
    test        :test
    # production :stmp, address: ENV['SMTP_PORT'], port: 1025
  end
end.load!
