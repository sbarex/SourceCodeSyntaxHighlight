#!/bin/sh

if [ ! "$1" ]; then
    echo "ERROR argument missing." >&2
    echo "Usage: chk_loc.sh <locale name>" >&2
    exit 1
fi

LOC=`echo $1 | sed 's/-//g'`

locale -a | sed 's/-//g' | grep -i "^${LOC}$" 2>&1 > /dev/null

if [ "$?" = "0" ]
then
  echo "yes"
else
  echo "no"
fi
