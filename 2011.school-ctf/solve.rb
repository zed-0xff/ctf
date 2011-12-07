#!/usr/bin/env ruby
require 'awesome_print'
require 'matrix'

tbl = "wihswaan\nreeecrle\nltttodyo\nuo:e?std\nemislaoi\nbelyrmoo\nfuinamer\nz!zh!yoz\n"
tbl.strip!
tbl.tr!("\n",'')

TBL = tbl.dup

KNOWN = 'hellodedmoroz!howareyou?'

kw = []
kw << 'hello' << 'ded' << 'moroz!' << 'how' << 'are' << 'you?'
kw << 'i' << 'am' << 'fine!'

kw << 'iwant' << 'to'
#kw << 'slay'
#kw << 'test' << 'my'
#kw << 'tesla' << 'in' << 'my'
#kw << 'secretly'
#kw << 'my'
#kw << 'is'
#kw << 'fuzzer'
#kw << 'name'
##kw << 'label' << 'of' << 'name'
#kw << 'tesla'
#kw << '!:'
##kw << 'itismy'
#kw << 'its'
#kw << 'toster'
#kw << 'of'
#kw << 'name'
kw << 'tell' << 'you'
kw << 'my'
kw << 'secret:'
kw << 'ssibearzz'
#kw << 'alien'

tbl = tbl.split('')
lastidx = -1
kw.each do |word|
  ctbl = tbl.dup
  indexes = []
  word.each_char do |c|
    if idx = tbl[(lastidx+1)..-1].index(c)
      idx += lastidx + 1
    else
      unless idx = tbl.index(c)
        puts "[!] can't find #{c.inspect}"
        exit
      end
    end
    indexes << idx
    lastidx = idx
  end
  indexes.each do |idx|
    ctbl[idx] = ctbl[idx].upcase.red
    tbl[idx] = ' '
  end
  puts ctbl.map{|c| c["["] ? c : c.gray }.join
end
tbl = (tbl-[' ']).join
puts tbl

p kw
puts
