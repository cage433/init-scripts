#!/bin/bash

input_file=$1
left_right_mid=$2
if [[ $left_right_mid = "-l" ]]; then
echo "sed -n '/<<</,/|||/p' $input_file"
  diff <(sed -n '/<<</{:a;n;/|||/b;p;ba}' $input_file) <(sed -n '/|||/{:a;n;/===/b;p;ba}' $input_file)
else 
  if [[ $left_right_mid = "-m" ]]; then
    diff <(sed -n '/<<</{:a;n;/|||/b;p;ba}' $input_file) <(sed -n '/===/{:a;n;/>>>/b;p;ba}' $input_file)
  else 
    if [[ $left_right_mid = "-r" ]]; then
      diff <(sed -n '/|||/{:a;n;/===/b;p;ba}' $input_file) <(sed -n '/===/{:a;n;/>>>/b;p;ba}' $input_file)
    fi
  fi
fi

