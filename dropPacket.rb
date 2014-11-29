#!/usr/bin/ruby

puts "Enter percentage of packets to be dropped: "
pktpct = gets.chomp

puts pktpct + " percent of packets will be dropped.\n"

randomNum = rand(100)

if randomNum < pktpct
    #drop packet
else
    #continue to destination


