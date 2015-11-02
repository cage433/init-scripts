#!/bin/bash

if [[ $# -ne 1 ]]; then
        echo "Requires a single parameter"
        exit 1
else
        for pid in `ps ax | awk -v cmd=$1 '$0 ~ cmd {print $1}'`; do cat /proc/$pid/cmdline; echo; done
fi

