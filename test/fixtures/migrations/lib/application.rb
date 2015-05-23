require_relative '../../sql_adapter'

Lotus::Model.configure do
  adapter type: :sql, uri: SQLITE_CONNECTION_STRING 
  mapping {}
end.load!
