#!/bin/sh
echo "removing MH artifacts from maven repository"
find ~/.m2/repository/org/opencastproject/ -exec rm -rf {} \; 2&>/dev/null

