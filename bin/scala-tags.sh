#!/bin/bash -e

# Not using this these days
#find . | egrep '\.((scala)|(java)|(lisp))$' | gtags -i -f -
find . | grep -v eventstore | egrep '\.((scala)|(java)|(lisp))$' | ctags -R -L -
if [[ -e eventstore ]];then
  # append these as they contain Instrument/Trade classes that would otherwise come first 
  find eventstore | egrep '\.((scala)|(java)|(lisp))$' | ctags -a -R -L -
fi


