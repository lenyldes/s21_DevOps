#!/bin/bash

df / | awk 'NR==2 {printf "%.2f MB", $3/1024}'