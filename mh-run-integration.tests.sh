#!/bin/sh
source ./config

cd $MH_DEV
mvn -Ptest -Dharness=server
cd -
