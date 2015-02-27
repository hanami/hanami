require_relative '../../../sql_adapter'
DB = Sequel.connect(SQLITE_CONNECTION_STRING)

DB.create_table :books do
  primary_key :id
  String  :name
end

module Collaboration
  class Application < Lotus::Application
    configure do
      layout :application
      load_paths << 'app'
      routes  'config/routes'

      serve_assets true

      assets << [
        'public',
        'vendor/assets',
        '../../vendor/assets'
      ]

      adapter type: :sql, uri: SQLITE_CONNECTION_STRING
      mapping 'config/mapping'
    end
  end
end
