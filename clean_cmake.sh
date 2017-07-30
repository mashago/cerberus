#!/bin/bash

echo "rm cmake cache begin..."
find . -name "cmake_install.cmake" | xargs rm -rf
find . -name "CMakeFiles" | xargs rm -rf
find . -name "Makefile" | xargs rm -rf
find . -name "CMakeCache.txt" | xargs rm -rf
#rm -rf ./sln/*
echo "rm cmake cache end..."
