#!/bin/bash

free | grep Mem | awk '{printf "%.3f GB", $4/1024/1024}'