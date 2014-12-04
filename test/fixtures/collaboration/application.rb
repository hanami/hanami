require 'lotus'
require 'lotus/model'
require 'sqlite3'

require 'lotus/model/adapters/sql_adapter'
db = Pathname.new(File.dirname(__FILE__)).join('../tmp/test.db')
db.dirname.mkpath      # create directory if not exist
db.delete if db.exist? # delete file if exist
SQLITE_CONNECTION_STRING = "sqlite://#{ db }"

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

      adapter type: :sql, uri: SQLITE_CONNECTION_STRING
      mapping 'config/mapping'
    end
  end
end
