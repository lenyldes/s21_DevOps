#!/bin/bash

cd "$(dirname "$0")" || exit 1
source ./config.sh
source ./validate.sh

source ./print_info.sh

# Вывод основной информации о системе
print_info "$col1_bg" "$col1_fg" "$col2_bg" "$col2_fg"

# Вывод цветовой схемы
echo ""
echo "Column 1 background = $col1_bg_str"
echo "Column 1 font color = $col1_fg_str"
echo "Column 2 background = $col2_bg_str"
echo "Column 2 font color = $col2_fg_str"
