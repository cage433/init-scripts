#!/bin/bash -e

# Not using this these days
#find . | egrep '\.((scala)|(java)|(lisp))$' | gtags -i -f -
find . | egrep '\.((scala)|(java)|(lisp))$' | ctags -R -L -


