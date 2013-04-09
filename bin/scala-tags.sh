#!/bin/bash -e

find . | egrep '\.((scala)|(java))$' | gtags -i -f -
find . | egrep '\.((scala)|(java))$' | ctags -R -L -


