#!/bin/bash

# Author: Tony Fahrion <tony.fahrion@de.clara.net>

# checks if the given value exists in the list (recommend string space separated)
# parameter $1 => value, $2 => string, used in "for in do done"
function is_in_list() {
  local VALUE="$1"
  local LIST="$2"
  
  for i in $LIST; do
    if [ "$VALUE" == "$i" ]; then
      return true
    fi
  done
  
  return false
}

# the opposit of is_in_list
function is_not_in_list() {
  is_in_list "$1" "$2" && false
}
