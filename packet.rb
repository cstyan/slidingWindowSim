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
#-- This source file contains the packet structure and functions for generating, 
#--	sending and receiving packets based on our protocol and packet function.
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
#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: makePacket
#--
#-- INTERFACE: makePacket(destIP, sourceIP, type, seqNum, ackNum)
#--              destIP: IP address for the destination host
#--				 sourceIP: IP address for the source host
#--              type: type of data(either a packet, ACK, of EOT)
#--				 seqNum: Sequence number of sent packets
#--				 ackNum: ACK number of sent packets
#--
#-- NOTES:
#-- This function creats a packet structure and fills it with data. It returns a complete packet struct
#----------------------------------------------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: getPacket
#--
#-- INTERFACE: getPacket(socket)
#--              Socket: socket for the transfer of data
#--
#-- NOTES:
#-- This function reads a packet from the socket
#----------------------------------------------------------------------------------------------------------------------
def getPacket(socket)
	packet = Packet.new
	size = 2048 + 6
	begin
		packet = Packet.new(socket.recvfrom_nonblock(size)[0])
	rescue Errno::EAGAIN
		IO.select([socket])
		retry
	end

	return packet
end

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: sendPacket
#--
#-- INTERFACE: sendPacket(socket, port, packet, *networkIP)
#--              socket: Socket used for the transfer of data
#--				 port: Port used for sockets to connect
#--              packet: Packet to send to host
#--				 *networkIP: IP address of network
#--
#-- NOTES:
#-- This function sends the packet after checking if the networkIP is empty
#----------------------------------------------------------------------------------------------------------------------
def sendPacket(socket, port, packet, *networkIP)
    if(networkIP.size == 0)
        socket.send(packet, 0, packet.destIP.to_s, port)
    else
        socket.send(packet, 0, networkIP[0], port)
    end
end
