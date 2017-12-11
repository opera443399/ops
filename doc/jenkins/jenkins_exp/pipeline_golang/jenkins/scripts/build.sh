#!/bin/bash
#
# 2017/12/11

echo "[#] __> BUILD INIT"
echo "[#] __> CHECK svrName = ${svrName}"
echo "[#] __> CHECK svrVar = ${svrVar}"
echo "[#] __> CHECK pwd = $(pwd)"

if [ -d "./${svrName}/" ]; then
  cd "./${svrName}/"
  echo "[#] __> GO GET"
  go get -v ./...
  echo "[#] __> GO BUILD"
  go build -v
  echo "[#] __> LIST dir $(pwd)"
  ls -l .
else
  echo "[#] __> ERROR dir ./${svrName}/ not exist"
  exit 1
fi
