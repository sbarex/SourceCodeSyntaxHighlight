#!/bin/sh

echo "Touch extra resource files"
# env

while IFS="" read -r p || [ -n "$p" ]
do
  printf '%s\n' "$p"
done < "$1"

