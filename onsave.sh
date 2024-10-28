#!/bin/bash

file=${1}

perl -i -p -e 's/\(([.\/\w-]+?.md(#[\w-]+)?)\)/({{< relref "\1" >}})/g' ${file}

currentDate=$(date "+%Y-%m-%dT%H:%M:%S+08:00")

perl -i -p -e "s/^date: (.+)/date: ${currentDate}/g" ${file}