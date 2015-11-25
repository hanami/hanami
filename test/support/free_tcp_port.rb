require 'socket'

class FreeTCPPort
  LOCALHOST = '127.0.0.1'.freeze

  def initialize
    socket = Socket.new(:INET, :STREAM, 0)
    socket.bind(Addrinfo.tcp(LOCALHOST, 0))
    @port = socket.local_address.ip_port
  end

  def to_s
    @port.to_s
  end
end
