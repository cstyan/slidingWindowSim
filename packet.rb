#!/usr/bin/env ruby 

#-----------------------------------------------------------------------------
#-- SOURCE FILE:    packet.rb - A Packet Structure
#--
#-- PROGRAM:        UDP Sliding Window Simulator
#--
#-- FUNCTIONS:      
#--                 def makePacket
#--                 def getPacket
#--                 def sendPacket
#--
#--
#-- NOTES:
#-- A simple client emulation program for testing servers. The program
#-- implements the following features:
#--     1. Ability to send variable length text strings to the server
#--     2. Number of times to send these strings is user definable
#--     3. Have the client maintain the connection for varying time durations
#--     4. Keep track of how many requests it made to the server, amount of
#--        data sent to the server, amount of time it took for the server to
#--        respond2
#--
#----------------------------------------------------------------------------*/

require 'socket'
require 'bit-struct'

# Packet Structure
class Packet < BitStruct
	octets		:destIP,	32
	octets      :sourceIP,  32
	unsigned	:type,		2
	unsigned	:seqNum,	16
	unsigned	:ackNum,	16
	rest		:data
end

# ==============================================================
# makePacket - Creates a Packet structure and fill it with data
# Takes in the following values:
# destIP - IP address of the destination host
# sourceIP - IP address of the source host
# type - int value between 0 and 2 (0 = ack, 1 = data, 2 = EOT)
# seqNum - Sequence Number
# ackNum - Acknowledgement Number
# data - Body content of the packet
#
# returns a Packet struct
# ==============================================================

def makePacket(destIP, sourceIP, type, seqNum, ackNum)
	packet = Packet.new

	packet.destIP = destIP
	packet.sourceIP = sourceIP
	packet.type = type
	packet.seqNum = seqNum
	packet.ackNum = ackNum

	if(type == 0)
		packet.data = "This is ack #{ackNum}"
	elsif(type == 1)
		packet.data = "This is packet #{seqNum}"
	else
		packet.data = "This is an EOT"
	end
		

	return packet
end

def getPacket(socket)
	packet = Packet.new
	size = 2048 + 5
	begin
		packet = Packet.new(socket.recvfrom_nonblock(size)[0])
	rescue Errno::EAGAIN
		IO.select([socket])
		retry
	end

	return packet
end

#if the array networkIP is empty then it calls
#a different version of the send function
def sendPacket(socket, port, packet, *networkIP)
    if(networkIP.size == 0)
        socket.send(packet, 0, packet.destIP.to_s, port)
    else
        socket.send(packet, 0, networkIP[0], port)
    end
end
