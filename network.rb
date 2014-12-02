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
#-- as a command line argument. Dropping of the packet is done by generating a
#-- random number between 1-100, if the number is greater than the entered rate
#-- then the packet is dropped.  This means that every packet has the same chance
#-- to be dropped as every other packet.
#-- 
#-- This network module also takes arguements for BER(Bit Error Rate), 
#-- average delay per packet, and IP addresses and port numbers for the
#-- transmitter and receiver.
#----------------------------------------------------------------------------*/

load 'packet.rb'
require 'logger'

puts "Port: "
$port = gets.chomp.to_i
puts "Enter a percentage of packets to be dropped: "
$pktpct = gets.chomp.to_i
puts "Enter the delay in seconds (0.05) "
$delay = gets.chomp.to_f

network_1 = UDPSocket.new
network_1.bind('', $port)

run = 1

$logFile = File.open('network.log', File::WRONLY | File::APPEND | File::CREAT)
$logger = Logger.new($logFile)
$logger.formatter = proc do |severity, datetime, progname, msg|
	"#{datetime}: #{msg}\n"
end

while(run == 1)
	randomNum = rand(1..100)
	packet = getPacket(network_1)
	if(randomNum > $pktpct)
		sleep($delay)
		sendPacket(network_1, $port, packet)

		if(packet.type == 1)
			puts "Data packet #{packet.seqNum} forwarded."
			$logger.info("Data packet #{packet.seqNum} forwarded.")
		elsif(packet.type == 0)
			puts "ACK packet #{packet.ackNum} forwarded."
			$logger.info("ACK packet #{packet.ackNum} forwarded.")
		else
			puts "EOT packet forwarded."
			$logger.info("EOT packet forwarded.")
		end
	else
		if(packet.type == 1)
			puts "Data packet #{packet.seqNum} dropped."
			$logger.info("Data packet #{packet.seqNum} dropped.")
		elsif(packet.type == 0)
			puts "ACK packet #{packet.ackNum} dropped."
			$logger.info("ACK packet #{packet.ackNum} dropped.")
		else
			puts "EOT packet dropped."
			$logger.info("EOT packet dropped.")
		end
	end
end
