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
#-- A simple client emulation program for testing an unreliable network. The program
#-- implements a sliding window protocol. 
#--   
#-- 
#----------------------------------------------------------------------------*/

load 'packet.rb'
require 'timeout'

#queue for the window
#technically it's an array because you can't
#access queue elements using array.[num]
$window = Array.new
#socket for sending/receiving
$socket = UDPSocket.new
$windowSize
$port
$networkIP
#IP address of the other client
$clientIP
#outgoing IP of the local machine
$localIP = UDPSocket.open{|s| s.connect("64.233.187.99", 1); s.addr.last}
$numPackets = 0
$currentSequenceNum = 0
$logFile
$logger


#generate the initial window
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

#sends our entire current window
def tx1(socket, port, destIP, networkIP,currentSequenceNum, numPackets, windowSize)
    i = 0
    puts "Sending window #{$window[0].seqNum} to #{$window[$windowSize - 1].seqNum}"
    $logger.info(Time.now + " Sending window #{$window[0].seqNum} to #{$window[$windowSize - 1].seqNum}")
    while i < $window.size
        packet = $window[i]
    	sendPacket($socket, $port, $window[i], networkIP)
        i += 1
    end
    packetsAcked = tx2(windowSize, destIP, currentSequenceNum)
    return packetsAcked
end

def tx2(windowSize, destIP, currentSequenceNum)
    i = 1
    acks = 0
    numLoop = windowSize
    packet = Packet.new
    if($window.size < windowSize)
        numLoop = $window.size
    end
    begin 
        timeout(0.5) do   
            while i < numLoop
                expectedAck = $window[0].seqNum
                packet = getPacket($socket)
                i += 1
                if(packet.type == 0 && packet.ackNum == expectedAck) 
                    lastSeqNum = $window[0].seqNum
                    $window.shift
                    if($currentSequenceNum != $numPackets)
                        newPacket = makePacket(destIP, $localIP, 1, $currentSequenceNum, 0)
                        puts "Pushing packet num #{$currentSequenceNum} to the queue"
                        $logger.info(Time.now + " Pushing packet num #{$currentSequenceNum} to the queue")
                        $currentSequenceNum += 1
                        acks += 1
                        $window.push(newPacket)
                    end
                end
            end
        end
    rescue Timeout::Error
        puts "Timed out!"
        $logger.info(Time.now + " Timed out!")
        return acks
    end
    return acks
end

def transmit(socket, numPackets, windowSize, destIP, networkIP, port)
    packetsSent = 0
    initialSequenceNum = 0
    $currentSequenceNum = genWindow(initialSequenceNum, windowSize, destIP)
    while($window.size != 0 && $currentSequenceNum != $numPackets)
        tx1(socket, port, destIP, networkIP, $currentSequenceNum, $numPackets, windowSize)
    end
    puts "Sending EOT"
    $logger.info(Time.now + " Sending EOT")
    sendPacket(socket, port, makePacket(destIP, $localIP, 2, 0, 0), networkIP)
end

def receive(recvIP, networkIP, socketA, port)
    run = 1
    while run == 1
        packet = getPacket($socket)
        sendPacket($socket, port, makePacket(recvIP, $localIP, 0, 0, packet.seqNum), networkIP)
        puts "sent an ACK"
        $logger.info(Time.now + " sent an ACK")
    end
    puts "EOT received, ending receive function."
    $logger.info(Time.now + " EOT received, ending receive function")
end

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
    $socket.bind('', $port)
    $socket.connect($networkIP, $port)
    $logFile = File.open('client.log', File::WRONLY | File::APPEND)
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
