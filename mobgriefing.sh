#!/bin/bash

mobgriefing_true() {
    mc cmd "gamerule mobgriefing true"
    mc cmd -q "say Game rule mobgriefing has been updated to true"
}

mobgriefing_false() {
    mc cmd "gamerule mobgriefing false"
    mc cmd -q "say Game rule mobgriefing has been updated to false"
}

 
case "$1" in
  on)
    mobgriefing_true
    ;;
  off)
    mobgriefing_false
    ;;
  *)
    echo "Usage: mobgriefing {on|off}"
    exit 1
    ;;
esac

exit 0
