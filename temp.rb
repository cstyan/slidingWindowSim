load 'packet.rb'
require 'timeout'

# ---Globals, cause they're cool---

#queue for the window
#technically it's an array because you can't
#access queue elements using array.[num]
$window = Array.new
#socket for sending/receiving
$socket = UDPSocket.new
# $sIn = UDPSocket.new
# #socket for sending
# $sOut = UDPSocket.new
$windowSize
$port
$networkIP
#IP address of the other client
$clientIP
#outgoing IP of the local machine
$localIP = UDPSocket.open{|s| s.connect("64.233.187.99", 1); s.addr.last}


#generate the initial window
def genWindow(initNum, windowSize, destIP)
    i = 1
    seqNum = initNum
    while(i <= windowSize.to_i)
        packet = makePacket(destIP, $localIP, 1, seqNum, 0)
        puts packet.data
        $window.push(packet)
	puts $window.size
        seqNum += 1
        puts $window[i - 1].data
	i += 1
    end
    return seqNum + 1
end

#sends our entire current window
def tx1(socket, port, destIP, networkIP,currentSequenceNum, numPackets, windowSize)
    i = 0
    while i < $window.size
        packet = $window[i]
        # sendPacket($socket, $port, makePacket(destIP, $localIP, 1, 0, 0), networkIP)
    	sendPacket($socket, $port, $window[i], networkIP)
        i += 1
    end
    puts "sent a window"
    packetsAcked = tx2(windowSize, destIP, currentSequenceNum)
    return packetsAcked
end

def tx2(windowSize, destIP, currentSequenceNum)
    #wait for acks in seq
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
                #we expect to receive the ACK for the seqNum at the front of the queue
                expectedAck = $window[0].seqNum
                packet = getPacket($socket)
                i += 1
                puts "packet recv'd"
                #if the packet is an ack and the ackNum is the ack we're expecting
                puts "Expected ACK: #{expectedAck}"
                puts "Packet ACK: #{packet.ackNum}"
                if(packet.type == 0 && packet.ackNum == expectedAck) 
                    lastSeqNum = $window[0].seqNum
                    $window.shift
                    newPacket = makePacket(destIP, $localIP, 1, currentSequenceNum, 0)
                    puts "Pushing packet num #{currentSequenceNum} to the queue"
                    currentSequenceNum += 1
                    acks += 1
                    $window.push(newPacket)
                end
            #if recv ack we expect, window.shift and push new packet to end
            end
        end
    rescue Timeout::Error
        puts "Timed out!"
        return acks
    end
    return acks
end

def transmit(socket, numPackets, windowSize, destIP, networkIP, port)
    #numer of packets sent and successfully ack'd
    packetsSent = 0
    #used to generate new packets to put into window
    #could be random if we want
    initialSequenceNum = 0

    currentSequenceNum = genWindow(initialSequenceNum, windowSize, destIP)
    while ((packetsSent = tx1(socket, port, destIP, networkIP, currentSequenceNum, numPackets, windowSize)) < numPackets)
        puts "Num packet #{numPackets}"
        puts "Packets sent #{packetsSent}"
    end
    #send eot
    #sendPacket(socket, port, makePacket(destIP, 2, 0, 0), networkIP)
end

#frame recv'd
# def rx1

# end

#check frame valid, send ACK
# def rx2

# end

#is this function necessary?
def receive(recvIP, networkIP, socketA, port)
    run = 1
    while run == 1
        #read a packet from the socket
        #rx1
        packet = getPacket($socket)
        # if packet.type = 2
        #     run = 0
        #     next
        # end
        #rx2
        #validate packet
        sendPacket($socket, port, makePacket(recvIP, $localIP, 0, 0, packet.seqNum), networkIP)
        puts "sent an ACK"
    end
    puts "EOT received, ending receive function"
end

def setup   
    puts "Setup, please configure the application accordingly."
    puts "Enter the window size:"
    $windowSize = gets.chomp.to_i
    puts "Enter a port:"
    $port = gets.chomp.to_i
    puts "Please enter network IP:"
    $networkIP = gets.chomp
    puts "Please enter the client IP:"
    $clientIP = gets.chomp
    $socket.bind('', $port)
    $socket.connect($networkIP, $port)
end

setup

#main script
run = 1
while(run == 1)
    continue = 1

    puts "Enter program state, 1 for SEND or 2 for RECEIVE:"
    state = gets.chomp
    
    if(state.to_i == 1)
        valid = 0
        num = 0
        while(valid == 0)
            puts "Enter the number of packets you want to send"
            num = gets.chomp.to_i
            if(num < $windowSize)
                next
            end
            valid = 1
        end
        transmit($socket, num, $windowSize, $clientIP, $networkIP, $port)
    elsif(state.to_i == 2)
        receive($clientIP, $networkIP, $socket, $port)
    else
        next
    end
end

puts "done"
