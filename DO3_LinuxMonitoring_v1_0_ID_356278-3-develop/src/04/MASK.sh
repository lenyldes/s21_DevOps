#!/bin/bash

interface=$(ip route show default | awk '{print $5}')
cidr=$(ip -o -f inet addr show dev "$interface" | awk '{print $4}' | cut -d'/' -f2)

val=$(( 0xFFFFFFFF << (32 - cidr) ))
printf "%d.%d.%d.%d\n" $(( (val >> 24) & 255 )) $(( (val >> 16) & 255 )) $(( (val >> 8) & 255 )) $(( val & 255 ))