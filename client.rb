#!/usr/bin/env ruby 

#-----------------------------------------------------------------------------
#-- SOURCE FILE:    client.rb - A UDP client
#--
#-- PROGRAM:        UDP Sliding Window Simulator
#--
#-- FUNCTIONS:      
#--                 def genWindow
#--                 def tx1
#--                 def tx2
#--                 def transmit
#--                 def receive
#--                 def setup
#--
#--
#-- NOTES:
#-- A simple UDP client emulation program for testing an unreliable network.
#-- This applictation implements a sliding window protocol. 
#----------------------------------------------------------------------------*/

load 'packet.rb'
require 'timeout'
require 'logger'

#queue for the window, technically an array since accessing queue elements is not possible
$window = Array.new
#socket for sending/receiving
$socket = UDPSocket.new
$windowSize
$port
$networkIP
#IP address of other client
$clientIP
#outgoing IP of the local machine
$localIP = UDPSocket.open{|s| s.connect("64.233.187.99", 1); s.addr.last}
$numPackets = 0
$timeout
$currentSequenceNum = 0
$logFile
$logger


#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: genWindow
#--
#-- INTERFACE: genWindow(initNum, windowSize, destIp)
#--              initNum: Initial sequence number 
#--              windowSize: Window size to use for sending windows
#--              destIP: IP Address for the destination
#--
#-- NOTES:
#-- This function handles all the tasks for generating the initial window. 
#----------------------------------------------------------------------------------------------------------------------
def genWindow(initNum, windowSize, destIP)
    i = 1
    seqNum = initNum
    while(i <= windowSize.to_i)
        packet = makePacket(destIP, $localIP, 1, seqNum, 0)
        $window.push(packet)
        seqNum += 1
        puts $window[i - 1].data
	i += 1
    end
    return seqNum + 1
end

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: tx1
#--
#-- INTERFACE: tx1(socket, port, destIP, networkIP, currentSequenceNum, numPackets, windowSize)
#--              socket: Socket for the transfer of packet data
#--              port: The port used for the sockets to connect
#--              destIP: IP address for the destination
#--              networkIP: IP address for the network emulator
#--              currentSequenceNum: The current sequence number for sent packets
#--              numPackets: Total number of packets needed to send for entire transfer
#--              windowSize: Window size to use for sending windows
#--
#-- NOTES:
#-- This function sends the entire current window
#----------------------------------------------------------------------------------------------------------------------
def tx1(socket, port, destIP, networkIP,currentSequenceNum, numPackets, windowSize)
    i = 0
    puts "Sending window #{$window[0].seqNum} to #{$window[$windowSize - 1].seqNum}"
    $logger.info(Time.now.asctime + " Sending window #{$window[0].seqNum} to #{$window[$windowSize - 1].seqNum}")
    while i < $window.size
        packet = $window[i]
    	sendPacket($socket, $port, $window[i], networkIP)
        i += 1
    end
    packetsAcked = tx2(windowSize, destIP, currentSequenceNum)
    return packetsAcked
end

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: tx2
#--
#-- INTERFACE: tx2(windowSize, destIP, currentSequenceNum)
#--              windowSize: Window size used for sending windows
#--              destIP: IP address for destination
#--              currentSequenceNum: The current sequence number for sent packets
#--
#-- NOTES:
#-- This function waits for ACKs in the proper sequence then pushes the packet number to the queue.
#----------------------------------------------------------------------------------------------------------------------
def tx2(windowSize, destIP, currentSequenceNum)
    i = 1
    acks = 0
    numLoop = windowSize
    packet = Packet.new
    if($window.size < windowSize)
        numLoop = $window.size
    end
    while i < numLoop
        expectedAck = $window[0].seqNum
        begin 
            timeout(0.5) do   
                packet = getPacket($socket)
                i += 1
                if(packet.type == 0 && packet.ackNum == expectedAck) 
                    lastSeqNum = $window[0].seqNum
                    $window.shift
                    if($currentSequenceNum != $numPackets)
                        newPacket = makePacket(destIP, $localIP, 1, $currentSequenceNum, 0)
                        puts "Pushing packet num #{$currentSequenceNum} to the queue"
                        $logger.info(Time.now.asctime + " Pushing packet num #{$currentSequenceNum} to the queue")
                        $currentSequenceNum += 1
                        acks += 1
                        $window.push(newPacket)
                    end
                end
            end
        rescue Timeout::Error
            puts "Timed out!"
            $logger.info(Time.now.asctime + " Timed out!")
            return acks
        end
    end
    return acks
end
#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: transmit
#--
#-- INTERFACE: transmit(socket, numPackets, windowSize, destIP, networkIP, port)
#--              socket: Socket used for the transfer of packet data 
#--              numPackets: Total number of packets needed to send for entire transfer
#--              windowSize: Window size used for sending windows
#--              destIP: IP address for destination
#--              networkIP: IP address for the network emulator
#--              port: The port used for the sockets to connect
#--
#-- NOTES:
#-- This function generates the initial window and calls tx1 to transmit windows until
#-- have sent packets and received acks for every packet sent
#----------------------------------------------------------------------------------------------------------------------
def transmit(socket, numPackets, windowSize, destIP, networkIP, port)
    packetsSent = 0
    initialSequenceNum = 0
    $currentSequenceNum = genWindow(initialSequenceNum, windowSize, destIP)
    while($window.size != 0 && $currentSequenceNum != $numPackets)
        tx1(socket, port, destIP, networkIP, $currentSequenceNum, $numPackets, windowSize)
    end
    puts "Sending EOT"
    $logger.info(Time.now.asctime + " Sending EOT")
    sendPacket(socket, port, makePacket(destIP, $localIP, 2, 0, 0), networkIP)
end

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: receive
#--
#-- INTERFACE: receive(recvIP, networkIP, socketA, port)
#--              recvIP: IP address for receiving client
#--              networkIP: IP address for the network emulator
#--              socketA: Socket used for the transfer of packet data
#--              port: The port used for the sockets to connect
#--              
#--
#-- NOTES:
#-- This function reads a packet thats received and sends corresponding ACK
#----------------------------------------------------------------------------------------------------------------------
def receive(recvIP, networkIP, socketA, port)
    run = 1
    useTimer = 0
    packet = Packet.new
    while run == 1
        if(useTimer == 0)
            packet = getPacket($socket)
            useTimer = 1
        else
            begin
                timeout(10) do
                    packet = getPacket($socket)
                end
            rescue Timeout::Error
                puts "Timed out!"
                $logger.info(Time.now.asctime + " Timed out!")
            end
        end
        sendPacket($socket, port, makePacket(recvIP, $localIP, 0, 0, packet.seqNum), networkIP)
        puts "sent an ACK"
        $logger.info(Time.now.asctime + " sent an ACK")
    end
    puts "EOT received, ending receive function."
    $logger.info(Time.now.asctime + " EOT received, ending receive function")
end

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: setup
#--
#-- NOTES:
#-- This function handles the setup of the client application by asking the user to input
#-- the window size, port, network IP, and client IP.
#----------------------------------------------------------------------------------------------------------------------
def setup   
    puts "Setup, please configure the application accordingly."
    puts "Enter the window size:"
    $windowSize = gets.chomp.to_i
    puts "Enter a port:"
    $port = gets.chomp.to_i
    puts "Please enter the network IP:"
    $networkIP = gets.chomp
    puts "Please enter the client IP:"
    $clientIP = gets.chomp
    puts "Please enter the timeout:"
    $timeout = gets.chomp.to_f
    $socket.bind('', $port)
    $socket.connect($networkIP, $port)
    $logFile = File.open('client.log', File::WRONLY | File::APPEND | File::CREAT)
    $logger =Logger.new($logFile)
end

setup

run = 1
while(run == 1)
    continue = 1

    puts "Enter program state, 1 for SEND or 2 for RECEIVE: "
    state = gets.chomp
    
    if(state.to_i == 1)
        valid = 0
        num = 0
        while(valid == 0)
            puts "Enter the number of packets you want to send: "
            $numPackets = gets.chomp.to_i
            if($numPackets < $windowSize)
                next
            end
            valid = 1
        end
        transmit($socket, $numPackets, $windowSize, $clientIP, $networkIP, $port)
    elsif(state.to_i == 2)
        receive($clientIP, $networkIP, $socket, $port)
    else
        next
    end
end

puts "Done."
