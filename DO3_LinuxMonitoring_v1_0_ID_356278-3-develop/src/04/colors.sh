#!/bin/bash

WHITE_T='\033[37m'
RED_T='\033[31m'
GREEN_T='\033[32m'
BLUE_T='\033[34m'
PURPLE_T='\033[35m'
BLACK_T='\033[30m'

WHITE_F='\033[47m'
RED_F='\033[41m'
GREEN_F='\033[42m'
BLUE_F='\033[44m'
PURPLE_F='\033[45m'
BLACK_F='\033[40m'

RESET='\033[0m'

bg_code() {
    case "$1" in
        1) printf '%s' "$WHITE_F" ;;
        2) printf '%s' "$RED_F" ;;
        3) printf '%s' "$GREEN_F" ;;
        4) printf '%s' "$BLUE_F" ;;
        5) printf '%s' "$PURPLE_F" ;;
        6) printf '%s' "$BLACK_F" ;;
    esac
}

fg_code() {
    case "$1" in
        1) printf '%s' "$WHITE_T" ;;
        2) printf '%s' "$RED_T" ;;
        3) printf '%s' "$GREEN_T" ;;
        4) printf '%s' "$BLUE_T" ;;
        5) printf '%s' "$PURPLE_T" ;;
        6) printf '%s' "$BLACK_T" ;;
    esac
}

color_name() {
    case "$1" in
        1) printf 'white' ;;
        2) printf 'red' ;;
        3) printf 'green' ;;
        4) printf 'blue' ;;
        5) printf 'purple' ;;
        6) printf 'black' ;;
    esac
}
