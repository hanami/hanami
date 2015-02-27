require 'lotus'
require 'lotus/model'

ADAPTER_TYPE =  if RUBY_ENGINE == 'jruby'
                  require 'jdbc/sqlite3'
                  Jdbc::SQLite3.load_driver
                  'jdbc:sqlite'
                else
                  require 'sqlite3'
                  'sqlite'
                end

require 'lotus/model/adapters/sql_adapter'
db = Pathname.new(File.dirname(__FILE__)).join('../tmp/test.db')
db.dirname.mkpath      # create directory if not exist
db.delete if db.exist? # delete file if exist
SQLITE_CONNECTION_STRING = "#{ADAPTER_TYPE}://#{ db }"

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
