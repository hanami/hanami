require_relative '../../../sql_adapter'

module Web 
  class Application < Lotus::Application
    configure do
      #Force different databse to prevent dirty data
      adapter type: :sql, uri: "#{SQLITE_CONNECTION_STRING_PATH}/websql.db"
      mapping {}
    end
  end
end
