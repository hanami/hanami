require 'hanami'
require 'hanami/cyg_utils/file_list'
require 'hanami/devtools/unit'

Hanami::CygUtils::FileList["./spec/support/**/*.rb"].each do |file|
  next if file.include?("hanami-plugin")
  require file
end
