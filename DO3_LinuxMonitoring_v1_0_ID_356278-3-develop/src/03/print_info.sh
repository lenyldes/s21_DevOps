#!/bin/bash

print_info() {
    local c1_bg=$1
    local c1_fg=$2
    local c2_bg=$3
    local c2_fg=$4

    local NAME_BG NAME_FG VAL_BG VAL_FG
    NAME_BG=$(bg_code "$c1_bg")
    NAME_FG=$(fg_code "$c1_fg")
    VAL_BG=$(bg_code "$c2_bg")
    VAL_FG=$(fg_code "$c2_fg")

    print_row() {
        local name=$1
        local value=$2
        printf '%b%s%b = %b%s%b\n' "$NAME_BG$NAME_FG" "$name" "$RESET" "$VAL_BG$VAL_FG" "$value" "$RESET"
    }

    print_row "HOSTNAME"        "$(./HOSTNAME.sh)"
    print_row "TIMEZONE"        "$(./TIMEZONE.sh)"
    print_row "USER"            "$(./USER.sh)"
    print_row "OS"              "$(./OS.sh)"
    print_row "DATE"            "$(./DATE.sh)"
    print_row "UPTIME"          "$(./UPTIME.sh)"
    print_row "UPTIME_SEC"      "$(./UPTIME_SEC.sh)"
    print_row "IP"              "$(./IP.sh)"
    print_row "MASK"            "$(./MASK.sh)"
    print_row "GATEWAY"         "$(./GATEWAY.sh)"
    print_row "RAM_TOTAL"       "$(./RAM_TOTAL.sh)"
    print_row "RAM_USED"        "$(./RAM_USED.sh)"
    print_row "RAM_FREE"        "$(./RAM_FREE.sh)"
    print_row "SPACE_ROOT"      "$(./SPACE_ROOT.sh)"
    print_row "SPACE_ROOT_USED" "$(./SPACE_ROOT_USED.sh)"
    print_row "SPACE_ROOT_FREE" "$(./SPACE_ROOT_FREE.sh)"
}
