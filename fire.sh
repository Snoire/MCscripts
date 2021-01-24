#!/bin/bash

doFireTick_true() {
    mc cmd "gamerule doFireTick true"
    mc cmd -q "say Game rule doFireTick has been updated to true"
}

doFireTick_false() {
    mc cmd "gamerule doFireTick false"
    mc cmd -q "say Game rule doFireTick has been updated to false"
}

 
case "$1" in
  on)
    doFireTick_true
    ;;
  off)
    doFireTick_false
    ;;
  *)
    echo "Usage: fire {on|off}"
    exit 1
    ;;
esac

exit 0
