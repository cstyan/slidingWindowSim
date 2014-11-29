load 'packet.rb'

#get port instead of defining it
port = 2000

network_1 = UDPSocket.new
#this binds to INADDR_ANY (any incomming IP address)
network_1.bind('', port.to_i)


run = 1

while(run == 1)
	packet = getPacket(network_1)
	puts packet.data
	sendPacket(network_1, port, makePacket(packet.destIP, 2, 0, 0, 0, packet.data))
end
