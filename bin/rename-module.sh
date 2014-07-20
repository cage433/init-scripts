#!/bin/bash

set -e

from=$1
to=$2

if [[ -z "$from" || -z "$to" ]]; then
  echo "Two parameters required"
  exit -1
fi

if [[ -e $from ]]; then
  echo "Renaming module"
  git mv $from/ $to
fi

echo "Changing all $from to $to"
find . -name '*.scala' | grep -v maker | xargs sed -i "s/\b$from\b/$to/g"

