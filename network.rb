#!/usr/bin/env ruby 

#-----------------------------------------------------------------------------
#-- SOURCE FILE:    network.rb - A simple "network" emulator
#--
#-- PROGRAM:        UDP Sliding Window Simulator
#--
#-- NOTES:
#-- This application emulates an unreliable channel in which packets are
#-- sent over. A client send packets to the this emulated network, in turn
#-- this network will forward the packets to the second client.
#-- 
#-- There is also a "noise" component that is included which randomly discards
#-- packets(and ACKs) to acheive a user specified bit error rate that is given 
#-- as a command line argument. 
#-- 
#-- This network module also takes arguements for BER(Bit Error Rate), 
#-- average delay per packet, and IP addresses and port numbers for the
#-- transmitter and receiver.
#----------------------------------------------------------------------------*/

load 'packet.rb'

puts "Port: "
$port = gets.chomp.to_i
puts "Enter a percentage of packets to be dropped: "
$pktpct = gets.chomp.to_i
puts "Enter the delay in seconds (0.05) "

network_1 = UDPSocket.new
network_1.bind('', $port)

run = 1

while(run == 1)
	randomNum = rand(100)
	packet = getPacket(network_1)
	puts packet.data
	if(randomNum > $pktpct)
		sleep (0.01)
		sendPacket(network_1, $port, packet)
	else
		puts "Packet dropped."
	end
end
