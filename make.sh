#!/bin/bash

ARGS=$*

# Rename the files
cp ./Tweak.mm ./Tweak.xm

# Build
make $ARGS

# Rename the files
#rm ./Tweak.xm
#echo "Deleted Tweak.xm"

exit 0