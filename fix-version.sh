#!/bin/bash
version=$1
version=`cat version.txt`
echo "::set-output name=version::$(echo $version| tr -d '[:space:]')"
