#!/usr/bin/env bash
set -e
source ./lib/util.sh
echo "Before exec: $(host_curto)"
exec ./test_sourcing.sh
