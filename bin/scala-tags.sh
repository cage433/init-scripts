#!/bin/bash -e

find . -name '*.scala' | gtags -i -f -
find . -name '*.scala' | ctags -R -L -


