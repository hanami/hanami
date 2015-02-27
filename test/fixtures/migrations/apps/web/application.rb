require_relative '../../../sql_adapter'
module Web 
  class Application < Lotus::Application
    configure do
      adapter type: :sql, uri: SQLITE_CONNECTION_STRING
    end
  end
end
