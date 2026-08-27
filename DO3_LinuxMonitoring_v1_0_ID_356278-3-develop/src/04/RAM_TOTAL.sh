#!/bin/bash

free | grep Mem | awk '{printf "%.3f GB", $2/1024/1024}'