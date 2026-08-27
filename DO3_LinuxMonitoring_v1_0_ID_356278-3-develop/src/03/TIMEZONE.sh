#!/bin/bash

echo "$(timedatectl show --property=Timezone --value) $(date +"UTC %:::z")"