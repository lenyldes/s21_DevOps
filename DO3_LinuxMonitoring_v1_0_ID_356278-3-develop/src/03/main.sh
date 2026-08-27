#!/bin/bash

cd "$(dirname "$0")" || exit 1

source ./validate.sh
source ./colors.sh
source ./print_info.sh

print_info "$col1_bg" "$col1_fg" "$col2_bg" "$col2_fg"