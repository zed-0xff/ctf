#!/bin/sh
for i in {1..75}; do
    # our host is #21, don't attack it
    if [ $i != 21 ]; then
       ./zork_attack.rb 10.12.$i.5 &
       sleep 1
    fi
done
