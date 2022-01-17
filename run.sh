#!/bin/sh

if ! cd lib/tasks/blizz/tests/; then
  exit 1
fi

if [ "${1}" = "v" ]; then
  rackup -p 4567
elif [ "${1}" = "q" ]; then
  rackup -p 4567 2>/dev/null 1>/dev/null
else
  rackup -p 4567 2>/dev/null
fi
