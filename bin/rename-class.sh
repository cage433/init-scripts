#!/bin/bash 

set -e

from=$1
to=$2

if [[ -z "$from" || -z "$to" ]]; then
  echo "Two parameters required"
  exit -1
fi

echo
echo "Changing all $from to $to"
find . -name '*.scala' | grep -v maker | xargs sed -i "s/\b$from\b/$to/g"
for file in `find . -name "$from".scala`; do
  new_file=`dirname $file`/$to.scala
  echo "git mv $file $new_file"
  git mv $file $new_file
done

echo
echo "Changing all "$from"Tests to "$to"Tests"
find . -name '*.scala' | grep -v maker | xargs sed -i "s/\b$from"Tests"\b/$to"Tests"/g"
for file in `find . -name "$from"Tests.scala`; do
  new_file=`dirname $file`/"$to"Tests.scala
  echo "git mv $file $new_file"
  git mv $file $new_file
done
