#!/bin/bash

cd "$(dirname "$0")" || exit 1

source ./validate.sh
source ./analyze.sh

analyze "$dir_path"
