load 'packet.rb'

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
$window = Queue.new

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
    return seqNum
end

def transmit(numPackets, windowSize, destIP)
    #used to generate new packets to put into window
    currentSequenceNum = 0
    genWindow(currentSequenceNum, windowSize, destIP)
end

def receive

end


#main script
run = 1
while(run == 1)
    continue = 1

    puts "Enter program state, 1 for SEND or 2 for RECEIVE:"
    state = gets.chomp
    
    if(state.to_i == 1)
        puts "Input the IP you would like to send to:"
        ip = gets.chomp
        while(continue == 1)
            puts "Enter the # of packets you would like to send:"
            num = gets.chomp
            packet = makePacket(ip, 1, 1, 1)
            #pass the port here
            sendPacket(client, networkIP, port, packet)
        end
    elsif(state.to_i == 2)
        while(continue == 1)
            packet = getPacket(client)
            puts packet.data
        end
    else

    end
end

puts "done"
