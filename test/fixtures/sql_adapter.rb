require 'lotus'
require 'lotus/model'
require 'lotus/model/adapters/sql_adapter'

db = Pathname.new(__dir__).join('../tmp/db')
db.dirname.mkpath        # create directory if not exist

sql = db.join('sql.db')
sql.delete if sql.exist? # delete file if exist

if Lotus::Utils.jruby?
  require 'jdbc/sqlite3'
  Jdbc::SQLite3.load_driver
  SQLITE_CONNECTION_STRING = "jdbc:sqlite:#{ sql }"
else
  require 'sqlite3'
  SQLITE_CONNECTION_STRING = "sqlite://#{ sql }"
end 

