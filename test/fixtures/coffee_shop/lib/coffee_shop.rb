require 'hanami/model'
require 'hanami/mailer'
Dir["#{ __dir__ }/coffee_shop/**/*.rb"].each { |file| require_relative file }

Hanami::Model.configure do
  # Database adapter
  #
  # Available options:
  #
  #  * Memory adapter
  #    adapter type: :memory, uri: 'memory://localhost/coffee_shop_development'
  #
  #  * SQL adapter
  #    adapter type: :sql, uri: 'sqlite://db/coffee_shop_development.sqlite3'
  #    adapter type: :sql, uri: 'postgres://localhost/coffee_shop_development'
  #    adapter type: :sql, uri: 'mysql://localhost/coffee_shop_development'
  #
  adapter type: :memory, uri: 'memory://localhost'

  ##
  # Database mapping
  #
  # Intended for specifying application wide mappings.
  #
  # You can specify mapping file to load with:
  #
  # mapping "#{__dir__}/config/mapping"
  #
  # Alternatively, you can use a block syntax like the following:
  #
  mapping do
    collection :orders do
      entity Order

      attribute :id,     Integer
      attribute :size,   String
      attribute :coffee, String
      attribute :qty,    Integer
    end
  end
end.load!
