#!/usr/bin/env ruby
boundaries = `grep boundary *.uncrypt`.strip.split("\n")
boundaries.each do |b|
  fname = b.split(':').first
  bound = b.split('"')[-1]
#  p [fname,bound]
  File.binread(fname).split(bound).each do |part|
    if part['MIME'] && part =~ /filename="(.*)"/
      fname = $1
      p fname
      data= part.split("\n\n",2)[1]
      File.open(fname,'w'){ |f| f<< data.unpack('m*').first }
    else
      #p part
    end
  end
end
