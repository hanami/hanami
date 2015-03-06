require 'lotus'
require 'lotus/model'
require 'lotus/model/adapters/sql_adapter'

db_path = Pathname.new(__dir__).join('../tmp/db')
db_path.dirname.mkpath        # create directory if not exist

sql = db_path.join('sql.db')
sql.delete if sql.exist? # delete file if exist

if Lotus::Utils.jruby?
  require 'jdbc/sqlite3'
  Jdbc::SQLite3.load_driver
  SQLITE_CONNECTION_STRING_PATH = "jdbc:sqlite:#{db_path}/"
else
  require 'sqlite3'
  SQLITE_CONNECTION_STRING_PATH = "sqlite://#{db_path}/"
end

SQLITE_CONNECTION_STRING = "#{SQLITE_CONNECTION_STRING_PATH}/sql.db"
 

