#!/bin/bash

df / | awk 'NR==2 {printf "%.2f MB", $2/1024}'