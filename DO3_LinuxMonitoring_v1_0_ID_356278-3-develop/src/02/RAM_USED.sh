#!/bin/bash

free | grep Mem | awk '{printf "%.3f GB", $3/1024/1024}'