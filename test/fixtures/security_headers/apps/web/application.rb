require 'hanami'
require 'hanami/model'

SECURITY_HEADERS_ADAPTER_TYPE =  if RUBY_ENGINE == 'jruby'
                  require 'jdbc/sqlite3'
                  Jdbc::SQLite3.load_driver
                  'jdbc:sqlite'
                else
                  require 'sqlite3'
                  'sqlite'
                end

require 'hanami/model/adapters/sql_adapter'
db = Pathname.new(File.dirname(__FILE__)).join('../tmp/test.db')
db.dirname.mkpath      # create directory if not exist
db.delete if db.exist? # delete file if exist
SECURITY_HEADERS_SQLITE_CONNECTION_STRING = "#{SECURITY_HEADERS_ADAPTER_TYPE}://#{ db }"

SECURITY_HEADERS_DB = Sequel.connect(SECURITY_HEADERS_SQLITE_CONNECTION_STRING)

SECURITY_HEADERS_DB.create_table :books do
  primary_key :id
  String  :name
end

module SecurityHeaders
  class Application < Hanami::Application
    configure do
      layout :application
      load_paths << 'app'
      routes  'config/routes'

      security.x_frame_options 'ALLOW ALL'
      security.content_security_policy "script-src 'self' https://apis.google.com"

      adapter type: :sql, uri: SECURITY_HEADERS_SQLITE_CONNECTION_STRING
      mapping 'config/mapping'
    end
  end
end
