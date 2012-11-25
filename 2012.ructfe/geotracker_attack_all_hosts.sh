#!/bin/sh
for i in {1..49}; do
    # our host is #12, don't attack it
    if [ $i != 12 ]; then
       ./geotracker_attack.rb 10.23.$i.3 &
    fi
done
