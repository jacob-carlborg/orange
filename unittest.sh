#!/bin/sh

dmd -g -unittest -ofunittest \
orange/core/*.d \
orange/serialization/*.d \
orange/serialization/archives/*.d \
orange/test/*.d \
orange/util/*.d \
orange/util/collection/*.d \
orange/xml/*.d \
tests/*.d

if [ "$?" = 0 ] ; then
  ./unittest
fi
