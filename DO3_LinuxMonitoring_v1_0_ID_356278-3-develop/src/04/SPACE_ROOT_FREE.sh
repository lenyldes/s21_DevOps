#!/bin/bash

df / | awk 'NR==2 {printf "%.2f MB", $4/1024}'