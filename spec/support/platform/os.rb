require 'rbconfig'

module Platform
  module Os
    def self.os?(name)
      current == name
    end

    def self.current
      case RbConfig::CONFIG['host_os']
      when /linux/  then :linux
      when /darwin/ then :macos
      end
    end
  end
end
