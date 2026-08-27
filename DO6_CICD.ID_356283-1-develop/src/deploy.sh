#!/bin/bash

scp ./DO lenyldes@192.168.1.103:/tmp/
ssh lenyldes@192.168.1.103 "sudo mv /tmp/DO /usr/local/bin/DO"