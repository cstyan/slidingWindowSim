load 'packet.rb'

#get port instead of defining it
$portIn
$portOut

# puts "Incomming port:"
# $portIn = gets.chomp.to_i
# puts "Outgoing port:"
# $portOut = gets.chomp.to_i
puts "Port:"
$port = gets.chomp.to_i

network_1 = UDPSocket.new
#this binds to INADDR_ANY (any incomming IP address)
network_1.bind('', $port)

run = 1

while(run == 1)
	#I am an idiot, don't make new packet
	packet = getPacket(network_1)
	puts packet.data
	sendPacket(network_1, $port, packet)
	# sendPacket(network_1, $port, makePacket(packet.destIP, 2, 0, 1))
end
