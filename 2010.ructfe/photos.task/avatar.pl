#!/usr/bin/perl

@name = map ord, split //, $ARGV[0];
@title = (map ord, split //, $ARGV[1])x128;

($\, $,) = ($/, ' ');             
for $i (0..127)
{
  print map {$name[($i + $_) % @name] ^ $title[$i] ^ $title[$_]} 0..127;
}