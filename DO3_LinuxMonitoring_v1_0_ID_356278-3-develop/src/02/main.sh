#!/bin/bash

cd "$(dirname "$0")" || exit 1

source ./validate.sh

all_info="HOSTNAME = $(./HOSTNAME.sh)
TIMEZONE = $(./TIMEZONE.sh)
USER = $(./USER.sh)
OS = $(./OS.sh)
DATE = $(./DATE.sh)
UPTIME = $(./UPTIME.sh)
UPTIME_SEC = $(./UPTIME_SEC.sh)
IP = $(./IP.sh)
MASK = $(./MASK.sh)
GATEWAY = $(./GATEWAY.sh)
RAM_TOTAL = $(./RAM_TOTAL.sh)
RAM_USED = $(./RAM_USED.sh)
RAM_FREE = $(./RAM_FREE.sh)
SPACE_ROOT = $(./SPACE_ROOT.sh)
SPACE_ROOT_USED = $(./SPACE_ROOT_USED.sh)
SPACE_ROOT_FREE = $(./SPACE_ROOT_FREE.sh)"

echo "$all_info"

echo ""
read -p "Сохранить данные в файл? (Y/N): " answer

if [[ "$answer" == "Y" || "$answer" == "y" ]]; then
    filename=$(date +"%d_%m_%y_%H_%M_%S").status
    
    echo "$all_info" > "$filename"
    
    echo "Данные сохранены в файл: $filename"
else
    echo "Сохранение отменено."
fi