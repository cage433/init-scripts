#!/bin/bash -e

find . | egrep '\.((scala)|(java)|(lisp))$' | gtags -i -f -
find . | egrep '\.((scala)|(java)|(lisp))$' | ctags -R -L -


