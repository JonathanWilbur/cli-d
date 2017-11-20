#!/bin/sh
mkdir -p ./documentation
mkdir -p ./documentation/html
mkdir -p ./build
mkdir -p ./build/executables
mkdir -p ./build/interfaces
mkdir -p ./build/libraries
mkdir -p ./build/objects
    
dmd \
./source/cli.d \
-Dd./documentation/html \
-Hd./build/interfaces \
-op \
-of./build/libraries/cli.lib \
-Xf./documentation/cli.json \
-lib \
-cov \
-profile \
-release \
-O

# Delete object files that get created.
# Yes, I tried -o- already. It does not create the executable either.
rm -f ./build/executables/*.o