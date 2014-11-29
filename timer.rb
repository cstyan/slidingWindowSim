require 'timeout'
require 'socket'

some_socket = UDPSocket.new()

begin 
    timeout(5) do
        message, client_address = some_socket.recvfrom(1024)
    end
rescue Timeout::Error
    puts "Timed out!"
end