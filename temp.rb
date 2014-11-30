load 'packet.rb'

#generate the initial window
def genWindow(initNum, windowSize, destIP)
    i = 1
    seqNum = initNum
    while(i <= windowSize)
        packet = makePacket(destIP, 1, seqNum, 0)
        $window.push(packet)
        seqNum += 1
        i += 1
    end
    return seqNum + 1
end

#sends our entire current window
def tx1(socket, port, destIP, networkIP,currentSequenceNum, numPackets, windowSize)
    i = 0
    while i < $window.size
        packet = $window[i]
        sendPacket(socket, port, packet, networkIP)
    end
    packetsAcked = tx2(windowSize, destIP, currentSequenceNum)
    return packetsAcked
end

def tx2(windowSize, destIP, currentSequenceNum)
    #wait for acks in seq
    i = 0
    numLoop = windowSize
    if($window.size < windowSize)
        numLoop = $window.size
    end
    while i < numLoop
        #we expect to receive the ACK for the seqNum at the front of the queue
        expectedAck = $window[0].seqNum
        recvd = getPacket($recv)
        packet = recvd[0]
        #if the packet is an ack and the ackNum is the ack we're expecting
        if(packet.type == 0 && packet.ackNum == expectedAck) 
            lastSeqNum = window 
            $window.shift
            newPacket = makePacket(destIP, 1, currentSequenceNum, 0)
            puts "Pushing packet num #{currentSequenceNum} to the queue"
            currentSequenceNum += 1
            $windowSize.push(newPacket)
        end
    #if recv ack we expect, window.shift and push new packet to end
end

def transmit(socket, numPackets, windowSize, destIP, networkIP, port)
    #numer of packets sent and successfully ack'd
    packetsSent = 0
    #used to generate new packets to put into window
    #could be random if we want
    initialSequenceNum = 0

    currentSequenceNum = genWindow(initialSequenceNum, windowSize, destIP)

    while ((packetsSent = tx1(client, port, destIP, networkIP, currentSequenceNum, numPackets, windowSize)) < numPackets)
    end
    #send eot
    sendPacket(socket, port, makePacket(destIP, 2, 0, 0), networkIP)
end

#frame recv'd
# def rx1

# end

#check frame valid, send ACK
# def rx2

# end

#is this function necessary?
def receive(recvIP, networkIP, socket, port)
    run = 1
    while run == 1
        #read a packet from the socket
        #rx1
        packet = getPacket($recv)
        if packet.type = 2
            run = 2
            next
        end
        #rx2
        #validate packet
        sendPacket(socket, port, makePacket(recvIP, 0, 0, packet.seqNum), networkIP)
end

#get a port isntead of defining it
puts "Enter the port #:"
port = gets.chomp


client = UDPSocket.new
puts "Enter the network IP:"
networkIP = gets.chomp
client.connect(networkIP, port)

puts "Enter the window size:"
winSize = gets.chomp

#global queue for the window
#technically it's an array because you can't
#access queue elements using .[]
$window = Array.new

#global socket for receiving
$recv = UDPSocket.new



#main script
run = 1
while(run == 1)
    continue = 1

    puts "Enter program state, 1 for SEND or 2 for RECEIVE:"
    state = gets.chomp
    
    if(state.to_i == 1)
        puts "Input the IP you would like to send to:"
        ip = gets.chomp
        $recv.bind(ip, port.to_i)
        valid = 0
        num = 0
        while(valid == 0)
            puts "Enter the number of packets you want to send"
            num = gets.chomp
            if(num > winSize)
                next
            end
            valid = 1
        end

        # while(continue == 1)
        #     puts "Enter the # of packets you would like to send:"
        #     num = gets.chomp
        #     packet = makePacket(ip, 1, 1, 1)
        #     #pass the port here
        #     sendPacket(client, port, packet, networkIP)
        # end
        transmit(client, num, winSize, ip, networkIP, port)
    elsif(state.to_i == 2)
        $recv.bind('', port.to_i)
        puts "Input the IP you want to receive"
        recvIP = gets.chomp
        # while(continue == 1)
        #     packet = getPacket($recv)
        #     puts packet.data
        # end
        receive(recvIP, networkIP, $recv, port)
    else

    end
end

puts "done"
